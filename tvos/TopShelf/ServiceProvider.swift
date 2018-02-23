import Foundation
import TVServices
import UIKit

class ServiceProvider: NSObject, TVTopShelfProvider {
    
    let server_ip = "192.168.0.60"
    var cache = ""

    let topShelfStyle: TVTopShelfContentStyle = .inset
    
    var topShelfItems: [TVContentItem] {
        let vpnItem = getFlag()
        return [vpnItem]
    }
    
    func getFlag()->TVContentItem {
        var flagpath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("flag_\(cache).png")

        let vpnIdentifier = TVContentIdentifier(identifier: "vpn_flag", container: nil)!
        let vpnItem = TVContentItem(contentIdentifier: vpnIdentifier)!
        vpnItem.imageShape = .extraWide
        vpnItem.setImageURL(flagpath, forTraits:.userInterfaceStyleLight)
        vpnItem.setImageURL(flagpath, forTraits:.userInterfaceStyleDark)
        
        if let country = try? String(contentsOf: URL(string: "http://\(server_ip)/country/")!)
        {
            cache = country
            flagpath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("flag_\(country).png")
            if !FileManager.default.fileExists(atPath: flagpath.path) {
                guard let data = try? Data(contentsOf: URL(string: "http://\(self.server_ip)/flag/")!) else { print("error getting data"); return vpnItem }
                guard let _ = try? data.write(to: flagpath) else { print("write error");return vpnItem }
            }
            vpnItem.setImageURL(flagpath, forTraits:.userInterfaceStyleLight)
            vpnItem.setImageURL(flagpath, forTraits:.userInterfaceStyleDark)

        }
        
        NotificationCenter.default.post(name: NSNotification.Name.TVTopShelfItemsDidChange, object: nil)

        return vpnItem
    }

}
