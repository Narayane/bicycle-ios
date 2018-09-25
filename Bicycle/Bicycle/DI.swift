import Foundation
import Dip
import Dip_UI

extension DependencyContainer {
    
    func configure() {
        registerCommonModule()
        registerOnboardingModule()
    }
    
    private func registerCommonModule() {
        
        self.register(.singleton) { UIApplication.shared.delegate as! AppDelegate }
        
        // data source
        self.register(.singleton) { BICLocalDataSource() }
        self.register(.singleton) { BicycleDataSource() }
        self.register(.singleton) { CityBikesDataSource() }
        self.register(.singleton) { UserDefaults.standard }
        
        // repository
        self.register(.singleton) { try BICContractRepository(appDelegate: self.resolve(), bicycleDataSource: self.resolve(), localDataSource: self.resolve(), preferenceRepository: self.resolve()) }
        self.register(.singleton) { try BICPreferenceRepository(bicycleDataSource: self.resolve(), userDefaults: self.resolve()) }
    }
    
    private func registerOnboardingModule() {
        
        // view model
        self.register(.unique) { try BICSplashViewModel(contractRepository: self.resolve(), preferenceRepository: self.resolve()) }
        
        // view
        self.register(storyboardType: BICSplashViewController.self, tag: "Splash")
            .resolvingProperties { container, vc in
                vc.viewModel = try container.resolve() as BICSplashViewModel
        }
    }
    
    private func registerHomeModule() {
        
        // view model
        self.register(.unique) { BICMapViewModel() }
        self.register(.unique) { try BICHomeViewModel(contractService: self.resolve()) }
        
        // view
        self.register(storyboardType: BICHomeViewController.self, tag: "Home")
            .resolvingProperties { container, vc in
                vc.viewModelMap = try container.resolve() as BICMapViewModel
                vc.viewModelHome = try container.resolve() as BICHomeViewModel
        }
    }
}
