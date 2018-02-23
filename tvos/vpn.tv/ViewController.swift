import UIKit
import TVServices

class ViewController: UIViewController {
    
    let server_ip = "192.168.0.60"
    
    @IBOutlet weak var country: UIImageView!
    @IBOutlet weak var mainStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainStackView.spacing = 15.0
        mainStackView.distribution = .fillEqually
        self.updateUI()
        view.backgroundColor = UIColor(red:0.61, green:0.61, blue:0.61, alpha:1.0)
        NotificationCenter.default.addObserver(forName: Notification.Name.UpdateMenu, object: nil, queue: nil){ _ in self.updateUI() }
    }
    
    func updateUI(){
        self.setFlag()
        callAPI("/all/", successHandler:  { (data) in
            guard let all = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Bool] else { return }
            DispatchQueue.main.async {
                for aView in self.mainStackView.arrangedSubviews {
                    self.mainStackView.removeArrangedSubview(aView)
                    aView.removeFromSuperview()
                }
                var off = ButtonType.disabled
                all.sorted(by: { $0.0.lowercased() < $1.0.lowercased() } ).forEach { item in
                    if item.value {
                        off = ButtonType.off
                    }
                    let current  = item.value ? ButtonType.current : ButtonType.normal
                    self.mainStackView.addArrangedSubview( self.makeMenuItem(item.key, type: current ) )
                }
                self.mainStackView.addArrangedSubview(self.makeMenuItem("OFF", type: off))
                self.loading(false)
            }
        })
        
    }
    
    func setFlag(){
        guard let url = URL(string: "http://\(server_ip)/flag/") else { return }
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if error != nil {
                return
            }
            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                return
            }
            DispatchQueue.main.async {
                self.country.image = UIImage(data: data!)
                NotificationCenter.default.post(name: NSNotification.Name.TVTopShelfItemsDidChange, object: nil)
            }
            }.resume()
    }
    
    
    func makeMenuItem(_ text: String, type: ButtonType) -> UIButton {
        let myButton = UIButton(type: UIButtonType.system)
        
        myButton.setTitle(text, for: .normal)
        myButton.setTitleColor(UIColor.white, for: .normal)
        myButton.setTitleColor(UIColor.black, for: .focused)
        myButton.backgroundColor = UIColor(red:0.81, green:0.81, blue:0.81, alpha:1.0)
        
        switch type {
        case .off:
            myButton.setTitleColor( UIColor.red, for: .focused)
        case .disabled:
            myButton.setTitleColor( UIColor.red, for: .focused)
            myButton.setTitle("OFF   ✔︎", for: .normal)
        case .current:
            myButton.setTitle("\(text)   ✔︎", for: .normal)
        default:
            ()
        }
        myButton.tag = type.rawValue
        myButton.addTarget(self, action: #selector(self.setButtonAction(_:)), for: .primaryActionTriggered)
        return myButton
    }
    
    @objc func setButtonAction(_ sender:UIButton!){
        self.loading(true)
        
        if sender.tag == ButtonType.off.rawValue {
            callAPI("/set/off/", successHandler: {(data) in
                self.updateUI()
            })
        } else {
            let country = (sender.titleLabel?.text)!
            if sender.tag == ButtonType.current.rawValue {
                callAPI("/restart/", successHandler: {(data) in
                    self.setFlag()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                        self.updateUI()
                    }
                })
            } else {
                callAPI("/set/\(country)", successHandler: {(data) in
                    let resp = String(data: data, encoding: .utf8) ?? "unknown"
                    if resp == "OK" {
                        self.setFlag()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
                            self.updateUI()
                        }
                    } else {
                        self.updateUI()
                    }
                })
            }
        }
    }
    
    func callAPI(_ action: String, successHandler: ((Data) -> Swift.Void)? = nil, errorHandler: (() -> Swift.Void)? = nil) {
        var request = URLRequest(url: URL(string: "http://\(server_ip)\(action)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!)
        request.httpMethod = "GET"
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.dataTask(with: request, completionHandler: { (responseData: Data?, response: URLResponse?, error: Error?) in
            if let r = responseData {
                successHandler?(r)
            } else {
                if let e = error {
                    print(e.localizedDescription)
                    errorHandler?()
                }
            }
        })
        task.resume()
    }
    
    func loading(_ show: Bool) {
        DispatchQueue.main.async {
            let tag = 808404
            if show {
                let full = UIView.init(frame: CGRect(x: 0, y: 0 , width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
                full.layer.cornerRadius = 10
                full.backgroundColor = UIColor.darkGray
                full.alpha = 0.7
                full.tag = tag

                let size = UIScreen.main.bounds.size.width / 5
                let square = UIView.init(frame: CGRect(x: UIScreen.main.bounds.size.width / 2 - size / 2 , y: UIScreen.main.bounds.size.height / 2 - size / 2, width: size, height: size))
                square.layer.cornerRadius = 10
                square.backgroundColor = UIColor.black
                
                let indicator = UIActivityIndicatorView()
                indicator.center = CGPoint(x: full.bounds.size.width/2, y: full.bounds.size.height/2)
                indicator.activityIndicatorViewStyle = .whiteLarge
                indicator.startAnimating()

                full.addSubview(square)
                full.addSubview(indicator)
                self.view.addSubview(full)
            } else {
                if let full = self.view.viewWithTag(tag) {
                    full.removeFromSuperview()
                }
            }
        }
    }
}

func <<T:RawRepresentable>(a:T, b:Int) -> Bool where T.RawValue == Int {
    return a.rawValue < b
}

enum ButtonType: Int {
    case off
    case disabled
    case normal
    case current
}


