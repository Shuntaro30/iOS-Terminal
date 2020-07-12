//
//  ViewController.swift
//  iOS Terminal
//
//  Created by Shuntaro Kasatani on 2020/07/10.
//  Copyright © 2020 Shuntaro Kasatani. All rights reserved.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var currentDirectory = NSHomeDirectory()
    var commandTo = 0
    var history = [String]()
    var isLs = false
    
    private var keyboardAppearObserver: Any?
    private var keyboardDisappearObserver: Any?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        textView.delegate = self
        textView.usesStandardTextScaling = true
        textView.tintColor = UIColor(named: "darkGreen")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.text = "\(UIDevice.current.name):~ "
        commandTo = textView.text.count
        currentDirectory = NSHomeDirectory()
        navigationItem.title = "\(UIDevice.current.name) ー ~"
        textView.becomeFirstResponder()
    }
    
    /*override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.text = "\(UIDevice.current.name):~ "
        commandTo = textView.text.count
        currentDirectory = NSHomeDirectory() + "/Documents"
        navigationItem.title = "\(UIDevice.current.name) ー ~"
        textView.becomeFirstResponder()
    }*/
    
    func isDirectory(_ dirName: String) -> Bool {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: dirName, isDirectory: &isDir) {
            if isDir.boolValue {
                return true
            }
        }
        return false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text != "\n" {
            if commandTo > range.location {
                return false
            } else {
                return true
            }
        } else {
            if commandTo <= textView.text.count {
                let string = textView.text[commandTo...textView.text.count]
                if !string.isEmpty {
                    history.append(string)
                }
                if currentDirectory != NSHomeDirectory() {
                    navigationItem.title = "\(UIDevice.current.name) ー \(NSString(string: currentDirectory).lastPathComponent) ー \(string)"
                } else {
                    navigationItem.title = "\(UIDevice.current.name) ー ~ ー \(string)"
                }
                if string.prefix(2) == "cd" {
                    if string.prefix(3) == "cd " {
                        // MARK: cd
                        if string.suffix(string.count - 3) == ".." || string.suffix(string.count - 3) == "../" {
                            let nsString = NSString(string: currentDirectory)
                            currentDirectory = nsString.deletingLastPathComponent
                        } else {
                            if string.suffix(string.count - 3) == "../.." || string.suffix(string.count - 3) == "../../" {
                                var nsString = NSString(string: currentDirectory)
                                currentDirectory = nsString.deletingLastPathComponent
                                nsString = NSString(string: currentDirectory)
                                currentDirectory = nsString.deletingLastPathComponent
                            } else if string.suffix(string.count - 3) == "~" || string.suffix(string.count - 3) == "~/" {
                                currentDirectory = NSHomeDirectory()
                            } else if string.suffix(string.count - 3) == "/" {
                                currentDirectory = NSOpenStepRootDirectory()
                            } else {
                                if FileManager.default.fileExists(atPath: currentDirectory + "/" + string.suffix(string.count - 3)) {
                                    if isDirectory(currentDirectory + "/" + string.suffix(string.count - 3)) {
                                        if currentDirectory == "/" {
                                            currentDirectory = "/" + string.suffix(string.count - 3)
                                        } else {
                                            currentDirectory = currentDirectory + "/" + string.suffix(string.count - 3)
                                        }
                                    } else {
                                        textView.text = textView.text + "\n" + "cd: \(string.suffix(string.count - 3)): Not a directory"
                                    }
                                } else {
                                    textView.text = textView.text + "\n" + "cd: \(string.suffix(string.count - 3)): No such file or directory"
                                }
                            }
                        }
                    } else {
                        if string.count != 2 {
                            textView.text = textView.text + "\n" + "\(string): command not found"
                        } else {
                            currentDirectory = NSHomeDirectory()
                        }
                    }
                    commandTo = textView.text.count
                } else if string.prefix(7) == "openApp" {
                    if string.prefix(8) == "openApp " {
                        // MARK: openApp
                        if let url = URL(string: "\(string.suffix(string.count - 8)):") {
                            UIApplication.shared.open(url)
                        } else {
                            textView.text = textView.text + "\n" + "openApp: \(string.suffix(string.count - 8)): Couldn't open app"
                        }
                    } else {
                        if string.count != 7 {
                            textView.text = textView.text + "\n" + "\(string): command not found"
                        } else {
                            textView.text = textView.text + "\n" + """
                            Usage: openApp [App Scheme Name]
                            help: open the App.
                            """
                        }
                    }
                    commandTo = textView.text.count
                } else if string == "pwd" {
                    // MARK: pwd
                    textView.text = textView.text + "\n" + currentDirectory
                    commandTo = textView.text.count
                } else if string == "ls" {
                    // MARK: ls
                    do {
                        for content in try FileManager.default.contentsOfDirectory(atPath: currentDirectory) {
                            textView.text = textView.text + "\n" + content
                            commandTo = textView.text.count
                        }
                        commandTo = textView.text.count
                    } catch {
                        textView.text = textView.text + "\n" + "ls: \(error.localizedDescription)"
                    }
                    if currentDirectory == "/" {
                        isLs = true
                    }
                    commandTo = textView.text.count
                } else if string.prefix(4) == "open" {
                    if string.prefix(5) == "open " {
                        // MARK: open
                        if string.suffix(string.count - 5).prefix(7) == "http://" || string.suffix(string.count - 5).prefix(8) == "https://" {
                            let url = URL(string: String(string.suffix(string.count - 5)))
                            if UIApplication.shared.canOpenURL(url!) {
                                UIApplication.shared.open(url!)
                            }
                        } else {
                            let url = URL(string: "http://" + String(string.suffix(string.count - 5)))
                            if UIApplication.shared.canOpenURL(url!) {
                                UIApplication.shared.open(url!)
                            }
                        }
                    } else {
                        if string.count != 4 {
                            textView.text = textView.text + "\n" + "\(string): command not found"
                        } else {
                            textView.text = textView.text + "\n" + """
                            Usage: open [Website URL]
                            Help: Open URL from a shell.
                            """
                        }
                    }
                    commandTo = textView.text.count
                } else if string.suffix(3) == "cat" {
                    if string.prefix(4) == "cat " {
                        // MARK: cat
                        let text = string.suffix(string.count - 4)
                        do {
                            let getString = try String(contentsOfFile: currentDirectory + "/" + text)
                            textView.text = textView.text + "\n" + getString
                        } catch {
                            textView.text = textView.text + "\ncat: \(error.localizedDescription)"
                        }
                    } else {
                        if string.count != 3 {
                            textView.text = textView.text + "\n" + "\(string): command not found"
                        } else {
                            commandTo = textView.text.count
                        }
                    }
                    commandTo = textView.text.count
                } else if string.suffix(3) == "vim" {
                    if string.prefix(4) == "vim " {
                        // MARK: vim
                        
                    } else {
                        if string.count != 3 {
                            textView.text = textView.text + "\n" + "\(string): command not found"
                        }
                    }
                    commandTo = textView.text.count
                } else if string.suffix(2) == "vi" {
                    if string.prefix(3) == "vi " {
                        // MARK: vi
                    } else {
                        if string.count != 2 {
                            textView.text = textView.text + "\n" + "\(string): command not found"
                        }
                    }
                    commandTo = textView.text.count
                } else if string == "history -c" {
                    history.removeAll()
                    commandTo = textView.text.count
                } else if string == "history" {
                    if history.count != 0 {
                        textView.text = textView.text + "\n" + String(history.count) + " history"
                        for i in 0...history.count - 1 {
                            textView.text = textView.text + "\n" + "    \(i + 1). \(history[i])"
                        }
                    }
                    commandTo = textView.text.count
                } else {
                    // MARK: command not found
                    if !string.isEmpty {
                        textView.text = textView.text + "\n" + "\(string): command not found"
                    }
                    commandTo = textView.text.count
                }
            }
            commandTo = textView.text.count
            if currentDirectory != NSHomeDirectory() {
                textView.text = "\(textView.text ?? "")\n\(UIDevice.current.name):\(NSString(string: currentDirectory).lastPathComponent) "
                navigationItem.title = "\(UIDevice.current.name) ー \(NSString(string: currentDirectory).lastPathComponent)"
                if isLs {
                    commandTo = textView.text.count + 1
                } else {
                    commandTo = textView.text.count
                }
            } else {
                textView.text = "\(textView.text ?? "")\n\(UIDevice.current.name):~ "
                navigationItem.title = "\(UIDevice.current.name) ー ~"
                if isLs {
                    commandTo = textView.text.count + 1
                } else {
                    commandTo = textView.text.count
                }
            }
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        keyboardAppearObserver = notificationCenter.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: nil) { (notification) in
                self.adjustForKeyboard(notification: notification)
        }
        
        keyboardDisappearObserver = notificationCenter.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: nil) { (notification) in
                self.adjustForKeyboard(notification: notification)
        }
    }
    
    @objc
    func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo
        
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardFrame.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            textView.contentInset = .zero
        } else {
            textView.contentInset = UIEdgeInsets(top: 0,
                                                 left: 0,
                                                 bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom,
                                                 right: 0)
        }
        
        textView.scrollIndicatorInsets = textView.contentInset
        
        guard let animationDuration =
            userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? Double else {
                    fatalError("*** Unable to get the animation duration ***")
        }
        
        guard let curveInt =
            userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else {
                fatalError("*** Unable to get the animation curve ***")
        }
        
        guard let animationCurve =
            UIView.AnimationCurve(rawValue: curveInt) else {
                fatalError("*** Unable to parse the animation curve ***")
        }
        
        UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve) {
            self.view.layoutIfNeeded()
            
            let selectedRange = self.textView.selectedRange
            self.textView.scrollRangeToVisible(selectedRange)
            
        }.startAnimation()
    }

}

extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}

extension UITextView {
    var numberOfLines: Int {
        // prepare
        var computingLineIndex = 0
        var computingGlyphIndex = 0
        // compute
        while computingGlyphIndex < layoutManager.numberOfGlyphs {
            var lineRange = NSRange()
            layoutManager.lineFragmentRect(forGlyphAt: computingGlyphIndex, effectiveRange: &lineRange)
            computingGlyphIndex = NSMaxRange(lineRange)
            computingLineIndex += 1
        }
        // return
        if textContainer.maximumNumberOfLines > 0 {
            return min(textContainer.maximumNumberOfLines, computingLineIndex)
        } else {
            return computingLineIndex
        }
    }
}
