import PracticalMacros
import Foundation
//let a = 17
//let b = 25

//let (result, code) = #stringify(a + b)
//let (result, code) = #stringify(a - b)
//let (result, code) = #stringify(4*a - 3*b)
//let (result, code) = #stringify("Stewart".lowercased())

//print("The value \(result) was produced by the code \"\(code)\"")
//let s = "https://www.createchsol.com"
////let url = #URL(s)
//let url = #URL("https://createchsol.com")
//print(url)
@CaseIdentifiable
enum Screen{
    case home, settings
    case profile(userID: Int)
    
    var title: String {
        "Some Title"
    }
    
    func show() {
        
    }
    

}
//@CaseIdentifiable
//struct User {
//    
//}
