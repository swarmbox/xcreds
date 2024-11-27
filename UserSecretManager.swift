//
//  UserSecretManager.swift
//  encryptor
//
//  Created by Timothy Perfitt on 11/20/24.
//

import Foundation
import CryptoKit

public struct UserSecretManager {

    public enum SecretKeys: String {
        case adminUsername
        case adminPassword
    }
     var secretKeeper: SecretKeeper
    
    public init(secretKeeper: SecretKeeper) {
        self.secretKeeper = secretKeeper
    }

    func secrets() throws -> Secrets {
        return try secretKeeper.secrets()

    }
    public func updateLocalAdminCredentials(user:SecretKeeperUser) throws{

        let secrets = try secrets()
        secrets.localAdmin=user
        try secretKeeper.addSecrets(secrets)
    }
    public func localAdminCredentials() throws -> SecretKeeperUser?{
        let secrets = try secrets()
        return secrets.localAdmin

    }
    public func updateUIDUser(fullName:String, rfidUID:Data, username:String, password:String, uid:NSNumber) throws {
        let secrets = try secrets()
        var hashedUID=Data(SHA256.hash(data: rfidUID))
        for _ in 0...99999 {
            hashedUID=Data(SHA256.hash(data: hashedUID+rfidUID))

        }

        secrets.uidUsers.userDict?[hashedUID] = try SecretKeeperUser(fullName: fullName, username: username, password: password, uid:uid, rfidUID: rfidUID)
        try secretKeeper.addSecrets(secrets)
    }

    public func setUIDUsers(_ users:RFIDUsers) throws {
        let secrets = try secrets()
        secrets.uidUsers=users
        try secretKeeper.addSecrets(secrets)
    }

    public func uidUser(uid:Data) throws -> SecretKeeperUser?{
        let secrets = try secrets()
        let hashedUID=Data(SHA256.hash(data: uid))

        let uidUsers = secrets.uidUsers
        return uidUsers.userDict?[hashedUID]
    }

    public func clearUIDUsers() throws {
        let secrets = try secrets()
        secrets.uidUsers.userDict = [:]
        try secretKeeper.addSecrets(secrets)
    }

    public func uidUsers() throws-> RFIDUsers {
        let secrets = try secrets()
        return secrets.uidUsers
    }
}
