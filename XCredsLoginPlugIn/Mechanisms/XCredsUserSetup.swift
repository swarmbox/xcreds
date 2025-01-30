//
//  XCredsUserSetup.swift
//
//

class XCredsUserSetup: XCredsBaseMechanism {

    @objc override func run() {
        TCSLogWithMark("~~~~~~~~~~~~~~~~~~~ XCredsUserSetup mech starting ~~~~~~~~~~~~~~~~~~~")

        let bundle = Bundle.findBundleWithName(name: "XCreds")

        if let bundle = bundle {
            let infoPlist = bundle.infoDictionary
            if let infoPlist = infoPlist, let build = infoPlist["CFBundleVersion"] {
                TCSLogInfoWithMark("------------------------------------------------------------------")
                TCSLogInfoWithMark("XCreds Login Build Number: \(build)")
                if DefaultsOverride.standardOverride.bool(forKey: "showDebug")==false {
                    TCSLogInfoWithMark("Log showing only basic info and errors.")
                    TCSLogInfoWithMark("Set debugLogging to true to show verbose logging with")
                    TCSLogInfoWithMark("sudo defaults write /Library/Preferences/com.twocanoes.xcreds showDebug -bool true")
                }
                else {
                    TCSLogInfoWithMark("To disable verbose logging:")
                    TCSLogInfoWithMark("sudo defaults delete /Library/Preferences/com.twocanoes.xcreds showDebug")

                }

                TCSLogInfoWithMark("------------------------------------------------------------------")
            }


        }
        do {
            let secretKeeper = try SecretKeeper(label: "XCreds Encryptor", tag: "XCreds Encryptor")
            let userManager = UserSecretManager(secretKeeper: secretKeeper)

            let users = try userManager.uidUsers()
            if let keys = users.userDict?.keys, keys.count>0{
                TCSLogWithMark("setting up tap users");
                self.setHint(type: .rfidUsers, hint: users as NSSecureCoding)
            }

            if let adminUser = try userManager.adminCredentials(){

                TCSLogWithMark("Setting Admin User from secure file for keychain reset")
                self.setHint(type: .localAdmin, hint: adminUser )
            }

            else if let aUsername = DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminUserName.rawValue), let aPassword =
                DefaultsOverride.standardOverride.string(forKey: PrefKeys.localAdminPassword.rawValue), aUsername.isEmpty==false, aPassword.isEmpty==false{

                TCSLogWithMark("Setting Admin User from prefs / override script for keychain reset")

                let localAdmin = try SecretKeeperUser(fullName: "", username: aUsername, password: aPassword, uid: -1, rfidUID: Data(), pin: nil)
                self.setHint(type: .localAdmin, hint: localAdmin as NSSecureCoding)
            }

        }
        catch {
            TCSLogWithMark(error.localizedDescription)
        }
        let _ = allowLogin()


    }
}
