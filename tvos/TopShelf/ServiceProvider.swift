import Foundation
import TVServices

class ServiceProvider: NSObject, TVTopShelfProvider {
    
    let server_ip = "192.168.0.60"
    var code = Date().timeIntervalSince1970
    var cache = ""
    
    override init() {
        super.init()
    }
    
    var topShelfStyle: TVTopShelfContentStyle {
        return .inset
    }
    
    var topShelfItems: [TVContentItem] {
        // Create an array of TVContentItems.
        let vpnIdentifier = TVContentIdentifier(identifier: "vpn_flag", container: nil)!
        let vpnItem = TVContentItem(contentIdentifier: vpnIdentifier)!

        if let content = try? String(contentsOf: URL(string: "http://\(server_ip)/country/")!) {
            if cache != content {
                code = Date().timeIntervalSince1970
                cache = content
            }
        }

        vpnItem.setImageURL(URL(string: "http://\(server_ip)/flag/\(code)"), forTraits:.userInterfaceStyleLight)
        vpnItem.setImageURL(URL(string: "http://\(server_ip)/flag/\(code)"), forTraits:.userInterfaceStyleDark)

        return [vpnItem]
    }
    
    
    
}


