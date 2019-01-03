//
//  Copyright © 2018 Bicycle (Sébastien BALARD)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import XCTest
import CoreLocation
import MapKit
@testable import Bicycle

class ContractTester: BICCoreDataTestCase {
    
    let toulouseContract = "{ \"country\": \"FR\", \"latitude\": 43.604652, \"name\": \"Toulouse\", \"station_count\": 278, \"radius\": 6000, \"url\": \"http://api.citybik.es/v2/networks/velo\", \"longitude\": 1.444209 }"
    let albiCenter = CLLocationCoordinate2D(latitude: 43.928601, longitude: 2.151699)
    let stOrensCenter = CLLocationCoordinate2D(latitude: 43.564757, longitude: 1.531124)
    
    var contract: BICContract!
    
    func testCreateContract() {
        XCTAssertNotNil(contract!.objectID)
        XCTAssertNotNil(contract!.center)
        XCTAssertNotNil(contract!.region)
        XCTAssertEqual(contract!.name, "Toulouse")
    }
    
    func testIntersectWithInsideRegion() {
        let region = MKCoordinateRegion(center: contract!.center, latitudinalMeters: 1000, longitudinalMeters: 1000)
        XCTAssertTrue(contract!.region.intersect(region))
    }
    
    func testIntersectWithSameRegion() {
        let region = MKCoordinateRegion(center: contract!.center, latitudinalMeters: 6000, longitudinalMeters: 6000)
        XCTAssertTrue(contract!.region.intersect(region))
    }
    
    func testIntersectWithIntersectingRegion() {
        let region = MKCoordinateRegion(center: stOrensCenter, latitudinalMeters: 2500, longitudinalMeters: 2500)
        XCTAssertTrue(contract!.region.intersect(region))
    }
    
    func testIntersectWithOutsideRegion() {
        let region = MKCoordinateRegion(center: albiCenter, latitudinalMeters: 3000, longitudinalMeters: 3000)
        XCTAssertFalse(contract!.region.intersect(region))
    }
    
    override func setUp() {
        super.setUp()
        let dto = BICContractDto(JSONString: toulouseContract)!
        contract = BICContract(dto: dto, in: context!)
        try! context!.save()
    }
    
    override func tearDown() {
        context!.delete(contract!)
        super.tearDown()
    }
}
