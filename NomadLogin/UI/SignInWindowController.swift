//
//  SignIn.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/20/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Cocoa
import Security.AuthorizationPlugin
import os.log
import NoMAD_ADAuth
import OpenDirectory
let uiLog = OSLog(subsystem: "menu.nomad.login.ad", category: "UI")
let checkADLog = OSLog(subsystem: "menu.nomad.login.ad", category: "CheckADMech")

@objc class SignInViewController: NSViewController, DSQueryable {

    //MARK: - setup properties
    var mech: MechanismRecord?
    var nomadSession: NoMADSession?
    var shortName = ""
    var domainName = ""
    var passString = ""
    var newPassword = ""
    var isDomainManaged = false
    var isSSLRequired = false
    var passChanged = false
    let sysInfo = SystemInfoHelper().info()
    var sysInfoIndex = 0

    @objc var visible = true
    override var acceptsFirstResponder: Bool {
        return true
    }
    //MARK: - IB outlets
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var localOnlyCheckBox: NSButton!
    @IBOutlet weak var stackView: NSStackView!

//    @IBOutlet weak var domain: NSPopUpButton!
    @IBOutlet weak var signIn: NSButton!
    @IBOutlet weak var imageView: NSImageView!

    var internalDelegate:XCredsMechanismProtocol?

    var delegate:XCredsMechanismProtocol? {
        set {
            TCSLogWithMark()
            internalDelegate=newValue
//            controlsViewController?.delegate = newValue
        }
        get {
            return internalDelegate
        }
    }

    //MARK: - Migrate Box IB outlets
    var migrate = false
    var migrateUserRecord : ODRecord?
    let localCheck = LocalCheckAndMigrate()
    var didUpdateFail = false
    var setupDone=false
    //MARK: - UI Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        TCSLogWithMark()
        setupLoginAppearance()
        //awakeFromNib gets called multiple times. guard against that.
        if setupDone == false {

//            updateLoginWindowInfo()
            setupDone=true

//            self.view.addSubview(controlsViewController.view)
//            let rect = NSMakeRect(0, 0, controlsViewController.view.frame.size.width,120)
//            controlsViewController.view.frame=rect
//            controlsViewController.delegate=self.delegate

//            TCSLogWithMark("Configure login window")
//            loginAppearance()
//
//            TCSLogWithMark("create background windows")
//            createBackground()
//
//            TCSLogWithMark("Become first responder")
//            username.becomeFirstResponder()
//
//            os_log("Finishing loading loginwindow", log: uiLog, type: .debug)
//
//            // Disabling due to it causing screen resizing during EULA
//            let notificationCenter = NotificationCenter.default
//            notificationCenter.addObserver(self,
//                                           selector: #selector(updateWindowAfterResize),
//                                           name: NSApplication.didChangeScreenParametersNotification,
//                                           object: nil)
        }
         
    }


//    fileprivate func createBackground() {
////        var image: NSImage?
//        // Is a background image path set? If not just use gray.
////        if let backgroundImage = getManagedPreference(key: .BackgroundImage) as? String  {
////            os_log("BackgroundImage preferences found.", log: uiLog, type: .debug)
////            image = NSImage(contentsOf: URL(fileURLWithPath: backgroundImage))
////        }
////
////        if let backgroundImageData = getManagedPreference(key: .BackgroundImageData) as? Data {
////            os_log("BackgroundImageData found", log: uiLog, type: .debug)
////            image = NSImage(data: backgroundImageData)
////        }
//        let backgroundImage = DefaultsHelper.backgroundImage()
//        let screenRect = NSScreen.screens[0].frame
//
//        if let backgroundImage = backgroundImage {
//            imageView.image?.size=screenRect.size
//            imageView.image=backgroundImage
//
//            backgroundImage.size=screenRect.size
//            imageView.imageScaling = .scaleProportionallyUpOrDown
//
//            imageView.frame=NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height-100)
//
//        }
//
//    }
//

    func loginTransition() {
        os_log("Transitioning... fade our UI away", log: uiLog, type: .debug)

        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 1.0
            context.allowsImplicitAnimation = true
        }, completionHandler: {
            os_log("Close all the windows", log: uiLog, type: .debug)
            self.visible = false
        })
    }
    
    
//    @objc fileprivate func updateWindowAfterResize() {
//
////        DispatchQueue.main.async{
////            if self.window?.isVisible ?? true {
////                os_log("Reconfiguring login window after screen change", log: uiLog, type: .debug)
////                self.loginAppearance()
////
////                os_log("Become first responder", log: uiLog, type: .debug)
////                self.username.becomeFirstResponder()
////            }
////        }
//    }
//    

    func setupLoginAppearance() {
        TCSLogWithMark()

        self.view.wantsLayer=true
        self.view.layer?.backgroundColor = CGColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.4)
        localOnlyCheckBox.isEnabled=true

//        let color = NSColor.white
//        let colorTitle = NSMutableAttributedString(attributedString: localOnlyCheckBox.attributedTitle)
//        let titleRange = NSMakeRange(0,colorTitle.length)
//
//        colorTitle.addAttributes([NSAttributedString.Key.foregroundColor : color], range: titleRange)
//        localOnlyCheckBox.attributedTitle=colorTitle
//
//        // make things look better
        TCSLog("Tweaking appearance")

        if let usernamePlaceholder = UserDefaults.standard.string(forKey: PrefKeys.usernamePlaceholder.rawValue){
            TCSLogWithMark("Setting username placeholder: \(usernamePlaceholder)")
            self.usernameTextField.placeholderString=usernamePlaceholder
        }

        if let passwordPlaceholder = UserDefaults.standard.string(forKey: PrefKeys.passwordPlaceholder.rawValue){
            TCSLogWithMark("Setting password placeholder")

            self.passwordTextField.placeholderString=passwordPlaceholder

        }
//        if UserDefaults.standard.bool(forKey: PrefKeys.shouldShowLocalOnlyCheckbox.rawValue) == false {
//            self.localOnlyCheckBox.isHidden = true
//        }
//        else {
//            //show based on if there is an AD domain or not
//            self.localOnlyCheckBox.isHidden = self.domainName.isEmpty
//        }
//        if let logoData = getManagedPreference(key: .LoginLogoData) as? Data {
//            os_log("Found LoginLogoData key has a value", log: uiLog, type: .debug)
//            if let image = NSImage(data: logoData) as NSImage? {
//                imageView.image = image
//            }
//        }
//
//        // check for Logo Alpha
//
//        if let alpha = getManagedPreference(key: .LoginLogoAlpha) as? Int {
//            os_log("Updating logo alpha value", log: uiLog, type: .debug)
//            switch alpha {
//            case 0 :
//                imageView.alphaValue = 0.0
//            case 1 :
//                imageView.alphaValue = 0.1
//            case 2 :
//                imageView.alphaValue = 0.2
//            case 3 :
//                imageView.alphaValue = 0.3
//            case 4 :
//                imageView.alphaValue = 0.4
//            case 5 :
//                imageView.alphaValue = 0.5
//            case 6 :
//                imageView.alphaValue = 0.6
//            case 7 :
//                imageView.alphaValue = 0.7
//            case 8 :
//                imageView.alphaValue = 0.8
//            case 9 :
//                imageView.alphaValue = 0.9
//            case 10 :
//                imageView.alphaValue = 1.0
//            default :
//                imageView.alphaValue = 0.0
//            }
//        }
//        TCSLogWithMark()
//
//        let rect = NSMakeRect(0, 0, self.window?.contentView?.frame.size.width ?? 100,120)
//
//        controlsViewController?.view.frame=rect

    }

    fileprivate func showResetUI() {
        TCSLogWithMark()

        let changePasswordWindowController = UpdatePasswordWindowController.init(windowNibName: NSNib.Name("UpdatePasswordWindowController"))


        changePasswordWindowController.window?.canBecomeVisibleWithoutLogin=true
        changePasswordWindowController.window?.isMovable = true
        changePasswordWindowController.window?.canBecomeVisibleWithoutLogin = true
        changePasswordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
        var isDone = false
        while (!isDone){
            DispatchQueue.main.async{
                TCSLogWithMark("resetting level")
                changePasswordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
            }

            let response = NSApp.runModal(for: changePasswordWindowController.window!)
            changePasswordWindowController.window?.close()
            TCSLogWithMark("response: \(response.rawValue)")

            if response == .cancel {
                isDone = true
                return
            }

            if let pass = changePasswordWindowController.password {
                newPassword = pass
            }
            guard let session = nomadSession else {

                TCSLogWithMark("invalid session")
                return
            }
            session.oldPass = passString
            session.newPass = newPassword
            os_log("Attempting password change for %{public}@", log: uiLog, type: .debug, shortName)
            TCSLogWithMark("Attempting password change")
            passChanged = true

            session.changePassword()

            didUpdateFail = false
            isDone = true
//            delegate?.setHint(type: .migratePass, hint: migrateUIPass)
//            completeLogin(authResult: .allow)
            return

        }


    }

    fileprivate func authFail(_ message: String?=nil) {
        TCSLogWithMark(message ?? "")
        nomadSession = nil
        passwordTextField.stringValue = ""
        passwordTextField.shake(self)
//        alertText.stringValue = message ?? "Authentication Failed"
        loginStartedUI()
    }

    /// Simple toggle to change the state of the NoLo window UI between active and inactive.
    fileprivate func loginStartedUI() {
        TCSLogWithMark()
        signIn.isEnabled = !signIn.isEnabled
        signIn.isHidden = !signIn.isHidden
        TCSLogWithMark()
        usernameTextField.isEnabled = !usernameTextField.isEnabled
        passwordTextField.isEnabled = !passwordTextField.isEnabled
        localOnlyCheckBox.isEnabled = !localOnlyCheckBox.isEnabled
        TCSLogWithMark()
    }


    /// When the sign in button is clicked we check a few things.
    ///
    /// 1. Check to see if the username field is blank, bail if it is. If not, animate the UI and process the user strings.
    ///
    /// 2. Check the user shortname and see if the account already exists in DSLocal. If so, simply set the hints and pass on.
    ///
    /// 3. Create a `NoMADSession` and see if we can authenticate as the user.
    @IBAction func signInClick(_ sender: Any) {
        TCSLogWithMark("Sign In button clicked")
        let strippedUsername = usernameTextField.stringValue.trimmingCharacters(in:  CharacterSet.whitespaces)

        if strippedUsername.isEmpty {
            usernameTextField.shake(self)
            TCSLogWithMark("No username entered")
            return
        }
        TCSLogWithMark()
        loginStartedUI()
        TCSLogWithMark()
        updateLoginWindowInfo()
        TCSLogWithMark()
        if self.domainName.isEmpty==true || self.localOnlyCheckBox.state == .on{
            TCSLogWithMark("do local auth only")
            if PasswordUtils.verifyUser(name: shortName, auth: passString)  {
                setRequiredHintsAndContext()
                completeLogin(authResult: .allow)
            }
            else {
                TCSLogWithMark("password check failed")
                authFail()
            }
            return

        }
        TCSLogWithMark("network auth.")
        networkAuth()

    }

    fileprivate func networkAuth() {
        nomadSession = NoMADSession.init(domain: domainName, user: shortName)
        TCSLogWithMark("NoMAD Login User: \(shortName), Domain: \(domainName)")
        guard let session = nomadSession else {
            TCSLogErrorWithMark("Could not create NoMADSession from SignIn window")
            return
        }
        session.useSSL = isSSLRequired
        session.userPass = passString
        session.delegate = self
        session.recursiveGroupLookup = getManagedPreference(key: .RecursiveGroupLookup) as? Bool ?? false
        
        if let ignoreSites = getManagedPreference(key: .IgnoreSites) as? Bool {
            os_log("Ignoring AD sites", log: uiLog, type: .debug)

            session.siteIgnore = ignoreSites
        }
        
        if let ldapServers = getManagedPreference(key: .LDAPServers) as? [String] {
            TCSLogWithMark("Adding custom LDAP servers")

            session.ldapServers = ldapServers
        }
        
        TCSLogWithMark("Attempt to authenticate user")
        session.authenticate()
    }


//    @IBAction func ChangePassword(_ sender: Any) {
//        guard newPassword.stringValue == newPasswordConfirmation.stringValue else {
//            os_log("New passwords didn't match", log: uiLog, type: .error)
////            alertText.stringValue = "New passwords don't match"
//            return
//        }
//
//        // set the passChanged flag
//
//        passChanged = true
//
//        //TODO: Terrible hack to be fixed once AD Framework is refactored
//        password.stringValue = newPassword.stringValue
//
//        session?.oldPass = oldPassword.stringValue
//        session?.newPass = newPassword.stringValue
//
//        os_log("Attempting password change for %{public}@", log: uiLog, type: .debug, shortName)
//
//        // disable the fields
//
//        oldPassword.isEnabled = false
//        newPassword.isEnabled = false
//        newPasswordConfirmation.isEnabled = false
//
//        session?.changePassword()
//    }


    /// Format the user and domain from the login window depending on the mode the window is in.
    ///
    /// I.e. are we picking a domain from a list, using a managed domain, or putting it on the user name with '@'.
    fileprivate func updateLoginWindowInfo() {

        TCSLogWithMark("Format user and domain strings")
        TCSLogWithMark()
        var providedDomainName = ""

        let strippedUsername = usernameTextField.stringValue.trimmingCharacters(in:  CharacterSet.whitespaces)
        shortName = strippedUsername


        TCSLogWithMark()
        if strippedUsername.range(of:"@") != nil && getManagedPreference(key: .ADDomain) != nil {
            shortName = (strippedUsername.components(separatedBy: "@").first)!

            providedDomainName = strippedUsername.components(separatedBy: "@").last!.uppercased()
            TCSLogWithMark(providedDomainName)
        }
        TCSLogWithMark()
        if strippedUsername.contains("\\") {
            os_log("User entered an NT Domain name, doing lookup", log: uiLog, type: .default)
            if let ntDomains = getManagedPreference(key: .NTtoADDomainMappings) as? [String:String],
                let ntDomain = strippedUsername.components(separatedBy: "\\").first?.uppercased(),
                let user = strippedUsername.components(separatedBy: "\\").last,
                let convertedDomain =  ntDomains[ntDomain] {
                    shortName = user
                    providedDomainName = convertedDomain
            } else {
                os_log("NT Domain mapping failed, wishing the user luck on authentication", log: uiLog, type: .default)
            }
        }
        if let prefDomainName=getManagedPreference(key: .ADDomain) as? String{

            domainName = prefDomainName
        }
        if domainName != "" && providedDomainName.lowercased() == domainName.lowercased() {
            TCSLogWithMark("ADDomain being used")
            domainName = providedDomainName.uppercased()
        }

        if providedDomainName == domainName {

        }
        else if !providedDomainName.isEmpty {
            TCSLogWithMark("Optional domain provided in text field: \(providedDomainName)")
            if getManagedPreference(key: .AdditionalADDomains) as? Bool == true {
                os_log("Optional domain name allowed by AdditionalADDomains allow-all policy", log: uiLog, type: .default)
                domainName = providedDomainName
                return
            }

            if let optionalDomains = getManagedPreference(key: .AdditionalADDomains) as? [String] {
                guard optionalDomains.contains(providedDomainName.lowercased()) else {
                    TCSLogWithMark("Optional domain name not allowed by AdditionalADDomains whitelist policy")
                    return
                }
                TCSLogWithMark("Optional domain name allowed by AdditionalADDomains whitelist policy")
                domainName = providedDomainName
                return
            }

            TCSLogWithMark("Optional domain not name allowed by AdditionalADDomains policy (false or not defined)")
        }
        
        if providedDomainName == "",
            let managedDomain = getManagedPreference(key: .ADDomain) as? String {
            TCSLogWithMark("Defaulting to managed domain as there is nothing else")
            domainName = managedDomain
        }

        TCSLogWithMark("Using domain from managed domain")
        return
    }


    //MARK: - Login Context Functions

    /// Set the authorization and context hints. These are the basics we need to passthrough to the next mechanism.
    fileprivate func setRequiredHintsAndContext() {
        TCSLogWithMark()
        TCSLogWithMark("Setting hints for user: \(shortName)")
        delegate?.setHint(type: .user, hint: shortName)
        delegate?.setHint(type: .pass, hint: passString)
        TCSLogWithMark()
        os_log("Setting context values for user: %{public}@", log: uiLog, type: .debug, shortName)
        delegate?.setContextString(type: kAuthorizationEnvironmentUsername, value: shortName)
        delegate?.setContextString(type: kAuthorizationEnvironmentPassword, value: passString)
        TCSLogWithMark()

    }


    /// Complete the NoLo process and either continue to the next Authorization Plugin or reset the NoLo window.
    ///
    /// - Parameter authResult:`Authorizationresult` enum value that indicates if login should proceed.
    fileprivate func completeLogin(authResult: AuthorizationResult) {
        if let delegate = delegate {

        }
        else {
            TCSLogWithMark("delegate not defined")

        }
        switch authResult {
        case .allow:
            TCSLogWithMark("Complete login process with allow")
            delegate?.allowLogin()
//            window?.close()

        case .deny:
            TCSLogWithMark("Complete login process with deny")
            delegate?.denyLogin(message:nil)

//            window?.close()

        default:
            TCSLogWithMark("Complete login process with unknown")
//            window?.close()
        }
        TCSLogWithMark("Complete login process")
//        let error = mech?.fPlugin.pointee.fCallbacks.pointee.SetResult((mech?.fEngine)!, authResult)
//        if error != noErr {
//            TCSLogWithMark("Got error setting authentication result", log: uiLog, type: .
//        }
        NSApp.stopModal()
    }



    //MARK: - Update Local User Account Methods

    fileprivate func showPasswordSync() {
        // hide other possible boxes
        TCSLogWithMark()

        let passwordWindowController = LoginPasswordWindowController.init(windowNibName: NSNib.Name("LoginPasswordWindowController"))

        passwordWindowController.window?.canBecomeVisibleWithoutLogin=true
        passwordWindowController.window?.isMovable = false
        passwordWindowController.window?.canBecomeVisibleWithoutLogin = true
        passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
        var isDone = false
        while (!isDone){
            DispatchQueue.main.async{
                TCSLogWithMark("resetting level")
                passwordWindowController.window?.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue)
            }

            let response = NSApp.runModal(for: passwordWindowController.window!)
            passwordWindowController.window?.close()

            if response == .cancel {
                isDone=true
                TCSLogWithMark("User cancelled resetting keychain or entering password. Denying login")
                completeLogin(authResult: .deny)

                return
            }

            let localPassword = passwordWindowController.password
            guard let localPassword = localPassword else {
                continue
            }
            do {
                os_log("Password doesn't match existing local. Try to change local pass to match.", log: uiLog, type: .default)
                let localUser = try getLocalRecord(shortName)
                try localUser.changePassword(localPassword, toPassword: passString)
                os_log("Password sync worked, allowing login", log: uiLog, type: .default)

                isDone=true
                delegate?.setHint(type: .existingLocalUserPassword, hint: localPassword)
                completeLogin(authResult: .allow)
                return
            } catch {
                os_log("Unable to sync local password to Network password. Reload and try again", log: uiLog, type: .error)
                return
            }


        }

    }
    

    fileprivate func showMigration() {

        //need to prompt for username and passsword to select an account. Perhaps use code from the cloud login.
//        //RunLoop.main.perform {
//        // hide other possible boxes
//        os_log("Showing migration box", log: uiLog, type: .default)
//
//        self.loginStack.isHidden = true
//        self.signIn.isHidden = true
//        self.signIn.isEnabled = true
//
//        // show migration box
//        self.migrateBox.isHidden = false
//        self.migrateSpinner.isHidden = false
//        self.migrateUsers.addItems(withTitles: self.localCheck.migrationUsers ?? [""])
//        //}
    }
    
//    @IBAction func clickMigrationOK(_ sender: Any) {
//        RunLoop.main.perform {
//            self.migrateSpinner.isHidden = false
//            self.migrateSpinner.startAnimation(nil)
//        }
//        
//        let migrateUIPass = self.migratePassword.stringValue
//        if migrateUIPass.isEmpty {
//            os_log("No password was entered", log: uiLog, type: .error)
//            RunLoop.main.perform {
//                self.migrateSpinner.isHidden = true
//                self.migrateSpinner.stopAnimation(nil)
//            }
//            return
//        }
//        
//        // Take a look to see if we are syncing passwords. Until the next refactor the easiest way to tell is if the picklist is hidden.
//        if self.migrateUsers.isHidden {
//            do {
//                os_log("Password doesn't match existing local. Try to change local pass to match.", log: uiLog, type: .default)
//                let localUser = try getLocalRecord(shortName)
//                try localUser.changePassword(migrateUIPass, toPassword: passString)
//                didUpdateFail = false
//                passChanged = false
//                os_log("Password sync worked, allowing login", log: uiLog, type: .default)
//                delegate?.setHint(type: .existingLocalUserPassword, hint: migrateUIPass)
//                completeLogin(authResult: .allow)
//                return
//            } catch {
//                os_log("Unable to sync local password to Network password. Reload and try again", log: uiLog, type: .error)
//                didUpdateFail = true
//                showPasswordSync()
//                return
//            }
//        }
//        guard let migrateToUser = self.migrateUsers.selectedItem?.title else {
//            os_log("Could not select user to migrate from pick list.", log: uiLog, type: .error)
//            return
//        }
//        do {
//            os_log("Getting user record for %{public}@", log: uiLog, type: .default, migrateToUser)
//            migrateUserRecord = try getLocalRecord(migrateToUser)
//            os_log("Checking existing password for %{public}@", log: uiLog, type: .default, migrateToUser)
//            if migrateUIPass != passString {
//                os_log("No match. Upating local password for %{public}@", log: uiLog, type: .default, migrateToUser)
//                try migrateUserRecord?.changePassword(migrateUIPass, toPassword: passString)
//            } else {
//                os_log("Okta and local passwords matched for %{public}@", log: uiLog, type: .default, migrateToUser)
//            }
//            // Mark the record to add an alias if required
//            os_log("Setting hints for %{public}@", log: uiLog, type: .default, migrateToUser)
//            delegate?.setHint(type: .existingLocalUserName, hint: migrateToUser)
//            delegate?.setHint(type: .existingLocalUserPassword, hint: migrateUIPass)
//            os_log("Allowing login", log: uiLog, type: .default, migrateToUser)
//            completeLogin(authResult: .allow)
//        } catch {
//            os_log("Migration failed with: %{public}@", log: uiLog, type: .error, error.localizedDescription)
//            return
//        }
//        
//        // if we are here, the password didn't work
//        os_log("Unable to migrate user.", log: uiLog, type: .error)
//        self.migrateSpinner.isHidden = true
//        self.migrateSpinner.stopAnimation(nil)
//        self.migratePassword.stringValue = ""
//        self.completeLogin(authResult: .deny)
//    }
//    
//    @IBAction func clickMigrationCancel(_ sender: Any) {
//        passChanged = false
//        didUpdateFail = false
//        completeLogin(authResult: .deny)
//    }
//    
//    @IBAction func clickMigrationNo(_ sender: Any) {
//        // user doesn't want to migrate, so create a new account
//        completeLogin(authResult: .allow)
//    }
    
//    @IBAction func clickMigrationOverwrite(_ sender: Any) {
//        // user wants to overwrite their current password
//        os_log("Password Overwrite selected", log: uiLog, type: .default)
//        localCheck.mech = self.mech
//        delegate?.setHint(type: .passwordOverwrite, hint: true)
//        completeLogin(authResult: .allow)
//    }
    
//    @IBAction func showNetworkConnection(_ sender: Any) {
//        username.isHidden = true
//        guard let windowContentView = self.window?.contentView, let wifiView = WifiView.createFromNib(in: .mainLogin) else {
//            os_log("Error showing network selection.", log: uiLog, type: .debug)
//            return
//        }
//
//        wifiView.frame = windowContentView.frame
//        let completion = {
//            os_log("Finished working with wireless networks", log: uiLog, type: .debug)
//            self.username.isHidden = false
//            self.username.becomeFirstResponder()
//        }
//        wifiView.set(completionHandler: completion)
//        windowContentView.addSubview(wifiView)
//    }
//
//    @IBAction func clickInfo(_ sender: Any) {
//        if sysInfo.count > sysInfoIndex + 1 {
//            sysInfoIndex += 1
//        } else {
//            sysInfoIndex = 0
//        }
//
//        systemInfo.title = sysInfo[sysInfoIndex]
//        os_log("System information toggled", log: uiLog, type: .debug)
//    }
//    func verify() {
//
//            if XCredsBaseMechanism.checkForLocalUser(name: shortName) {
//                TCSLogWithMark()
//                os_log("Verify local user login for %{public}@", log: uiLog, type: .default, shortName)
//
//                if getManagedPreference(key: .DenyLocal) as? Bool ?? false {
//                    os_log("DenyLocal is enabled, looking for %{public}@ in excluded users", log: uiLog, type: .default, shortName)
//
//                    var exclude = false
//
//                    if let excludedUsers = getManagedPreference(key: .DenyLocalExcluded) as? [String] {
//                        if excludedUsers.contains(shortName) {
//                            os_log("Allowing local sign in via exclusions %{public}@", log: uiLog, type: .default, shortName)
//                            exclude = true
//                        }
//                    }
//
//                    if !exclude {
//                        os_log("No exclusions for %{public}@, denying local login. Forcing network auth", log: uiLog, type: .default, shortName)
//                        networkAuth()
//                        return
//                    }
//                }
//                TCSLogWithMark()
//                if PasswordUtils.verifyUser(name: shortName, auth: passString) {
//                    TCSLogWithMark()
//                    os_log("Allowing local user login for %{public}@", log: uiLog, type: .default, shortName)
//                    setRequiredHintsAndContext()
//                    TCSLogWithMark()
//                    completeLogin(authResult: .allow)
//                    return
//                } else {
//                    os_log("Could not verify %{public}@", log: uiLog, type: .default, shortName)
//                    authFail()
//                    return
//                }
//            }
//
//    }

}


//MARK: - NoMADUserSessionDelegate
extension SignInViewController: NoMADUserSessionDelegate {

    func NoMADAuthenticationFailed(error: NoMADSessionError, description: String) {
        TCSLogWithMark("NoMADAuthenticationFailed: \(description)")
        
//        if passChanged {
//            os_log("Password change failed.", log: uiLog, type: .default)
//            os_log("Password change failure description: %{public}@", log: uiLog, type: .error, description)
//            oldPassword.isEnabled = true
//            newPassword.isEnabled = true
//            newPasswordConfirmation.isEnabled = true
//
//            newPassword.stringValue = ""
//            newPasswordConfirmation.stringValue = ""
//
////            alertText.stringValue = "Password change failed"
//            return
//        }
        
        switch error {
        case .PasswordExpired:
            TCSLogErrorWithMark("Password is expired or requires change.")
//            authFail()
//            delegate?.denyLogin(message:"Password is expired or requires change")

            showResetUI()
            return
        case .OffDomain:
            TCSLogErrorWithMark("OffDomain")

            if PasswordUtils.verifyUser(name: shortName, auth: passString)  {
                setRequiredHintsAndContext()
                completeLogin(authResult: .allow)
            } else {
                authFail()
            }

            TCSLogErrorWithMark("AD authentication failed, off domain.")
//            if getManagedPreference(key: .LocalFallback) as? Bool ?? false {
//                os_log("Local fallback enabled, passing off to local authentication", log: uiLog, type: .default)
//                return
//            } else {
//                authFail();
//                return
//            }
        default:
            TCSLogErrorWithMark("NoMAD Login Authentication failed with: \(description)")
//            if PasswordUtils.verifyUser(name: shortName, auth: passString)  {
//                setRequiredHintsAndContext()
//                completeLogin(authResult: .allow)
//            } else {
                authFail()
//            }
            return
        }
    }


    func NoMADAuthenticationSucceded() {

        if getManagedPreference(key: .RecursiveGroupLookup) as? Bool ?? false {
            nomadSession?.recursiveGroupLookup = true
        }
        
        if passChanged {
            // need to ensure the right password is stashed
            passString = newPassword
            passChanged = false
        }
        
        TCSLogWithMark("Authentication succeeded, requesting user info")
        nomadSession?.userInfo()
    }

//callback from ADAuth framework when userInfo returns
    func NoMADUserInformation(user: ADUserRecord) {
        
        var allowedLogin = true
        
        TCSLogWithMark("Checking for DenyLogin groups")
        
        if let allowedGroups = getManagedPreference(key: .DenyLoginUnlessGroupMember) as? [String] {
            TCSLogErrorWithMark("Found a DenyLoginUnlessGroupMember key value: \(allowedGroups.debugDescription)")
            
            // set the allowed login to false for now
            
            allowedLogin = false
            
            user.groups.forEach { group in
                if allowedGroups.contains(group) {
                    allowedLogin = true
                    TCSLogErrorWithMark("User is a member of %{public}@ group. Setting allowedLogin = true ")
                }
            }
        }
    
        if let ntName = user.customAttributes?["msDS-PrincipalName"] as? String {
            TCSLogWithMark("Found NT User Name: \(ntName)")
            delegate?.setHint(type: .ntName, hint: ntName)
        }
        
        if allowedLogin {
            
            setHints(user: user)

            // check for any migration and local auth requirements
            let localCheck = LocalCheckAndMigrate()
            localCheck.delegate = delegate
//            localCheck.mech = self.mech
            switch localCheck.run(userToCheck: user.shortName, passToCheck: passString) {

            case .fullMigration:
                showMigration()
            case .syncPassword:
                // first check to see if we can resolve this ourselves
                TCSLogWithMark("Sync password called.")
                showPasswordSync()


            case .errorSkipMigration, .skipMigration, .userMatchSkipMigration, .complete:
                completeLogin(authResult: .allow)
            }
        } else {
            authFail()
//            alertText.stringValue = "Not authorized to login."
            showResetUI()
        }
    }
    
    fileprivate func setHints(user: ADUserRecord) {
        TCSLogWithMark()
        os_log("NoMAD Login Looking up info for: %{public}@", log: uiLog, type: .default, user.shortName)
        setRequiredHintsAndContext()
        delegate?.setHint(type: .firstName, hint: user.firstName)
        delegate?.setHint(type: .lastName, hint: user.lastName)
        delegate?.setHint(type: .noMADDomain, hint: domainName)
        delegate?.setHint(type: .adGroups, hint: user.groups)
        delegate?.setHint(type: .fullName, hint: user.cn)
        delegate?.setHint(type: .kerberos_principal, hint: user.userPrincipal)
        delegate?.setHint(type: .ntName, hint: user.ntName)
        
        // set the network auth time to be added to the user record
        delegate?.setHint(type: .networkSignIn, hint: String(describing: Date.init().description))
    }

}


//MARK: - NSTextField Delegate
extension SignInViewController: NSTextFieldDelegate {
    public func controlTextDidChange(_ obj: Notification) {
        TCSLogWithMark()
        let passField = obj.object as! NSTextField
        passString = passField.stringValue
    }
}


//MARK: - ContextAndHintHandling Protocol
//extension SignIn: ContextAndHintHandling {}

extension NSWindow {

    func shakeWindow(){
        let numberOfShakes      = 3
        let durationOfShake     = 0.25
        let vigourOfShake : CGFloat = 0.015

        let frame : CGRect = self.frame
        let shakeAnimation :CAKeyframeAnimation  = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: frame.minX, y: frame.minY))

        for _ in 0...numberOfShakes-1 {
            shakePath.addLine(to: CGPoint(x: frame.minX - frame.size.width * vigourOfShake, y: frame.minY))
            shakePath.addLine(to: CGPoint(x: frame.minX + frame.size.width * vigourOfShake, y: frame.minY))
        }

        shakePath.closeSubpath()

        shakeAnimation.path = shakePath;
        shakeAnimation.duration = durationOfShake;

        self.animations = [NSAnimatablePropertyKey("frameOrigin"):shakeAnimation]
        self.animator().setFrameOrigin(self.frame.origin)
    }

}

