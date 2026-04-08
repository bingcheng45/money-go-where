@preconcurrency import AuthenticationServices
import Foundation
import UIKit

// MARK: - Errors

enum AccountError: Error {
    case notSupported
    case canceled
    case failed(String)
}

// MARK: - Credential state (framework-agnostic)

enum AppleCredentialState {
    case authorized
    case revoked
    case notFound
    case unknown
}

// MARK: - Protocol

protocol AccountProviding: Sendable {
    func bootstrapProfile(existing: UserProfile) -> UserProfile
    func signInWithApple() async throws -> UserProfile
    func appleCredentialState(for appleUserID: String) async -> AppleCredentialState
}

extension AccountProviding {
    func signInWithApple() async throws -> UserProfile {
        throw AccountError.notSupported
    }

    func appleCredentialState(for appleUserID: String) async -> AppleCredentialState {
        .notFound
    }
}

// MARK: - Local (no-op) implementation

struct LocalAccountService: AccountProviding {
    func bootstrapProfile(existing: UserProfile) -> UserProfile {
        if existing.displayName.isEmpty {
            var updated = existing
            updated.displayName = "MoneyGoWhere User"
            return updated
        }
        return existing
    }
}

// MARK: - Keychain

private enum KeychainStore {
    static let service = "com.moneygowhere.app"

    static func save(_ value: String, key: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - ASAuthorizationController coordinator

@MainActor
private final class SignInWithAppleCoordinator: NSObject {
    private var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    func signIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

extension SignInWithAppleCoordinator: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        MainActor.assumeIsolated {
            continuation?.resume(returning: credential)
            continuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        MainActor.assumeIsolated {
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

extension SignInWithAppleCoordinator: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }?
                .keyWindow ?? UIWindow()
        }
    }
}

// MARK: - Apple Account Service

final class AppleAccountService: AccountProviding {
    func bootstrapProfile(existing: UserProfile) -> UserProfile {
        // Keychain is the source of truth; if no stored userID, this is a local-only session
        guard KeychainStore.read(key: "apple.userID") != nil else { return existing }
        var updated = existing
        if updated.displayName.isEmpty, let name = KeychainStore.read(key: "apple.displayName") {
            updated.displayName = name
        }
        if updated.email == nil {
            updated.email = KeychainStore.read(key: "apple.email")
        }
        return updated
    }

    func signInWithApple() async throws -> UserProfile {
        // Hop to main actor — ASAuthorizationController requires UIKit presentation
        try await performSignIn()
    }

    func appleCredentialState(for appleUserID: String) async -> AppleCredentialState {
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: appleUserID)
            switch state {
            case .authorized:   return .authorized
            case .revoked:      return .revoked
            case .notFound:     return .notFound
            case .transferred:  return .unknown
            @unknown default:   return .unknown
            }
        } catch {
            return .unknown
        }
    }

    // MARK: Private

    @MainActor
    private func performSignIn() async throws -> UserProfile {
        let coordinator = SignInWithAppleCoordinator()
        let credential: ASAuthorizationAppleIDCredential
        do {
            credential = try await coordinator.signIn()
        } catch let error as ASAuthorizationError where error.code == .canceled {
            throw AccountError.canceled
        } catch {
            throw AccountError.failed(error.localizedDescription)
        }

        let userID = credential.user
        let email = credential.email
        let fullName: String? = credential.fullName.flatMap { components in
            let parts = [components.givenName, components.familyName]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: " ")
        }

        // Persist to Keychain (Apple only provides name/email on first sign-in)
        KeychainStore.save(userID, key: "apple.userID")
        if let email    { KeychainStore.save(email,    key: "apple.email") }
        if let fullName { KeychainStore.save(fullName, key: "apple.displayName") }

        // Fall back to Keychain values on re-authentication (when Apple returns nil name/email)
        let resolvedName  = fullName ?? KeychainStore.read(key: "apple.displayName") ?? "MoneyGoWhere User"
        let resolvedEmail = email    ?? KeychainStore.read(key: "apple.email")

        var profile = UserProfile.empty
        profile.appleUserID  = userID
        profile.displayName  = resolvedName
        profile.email        = resolvedEmail
        return profile
    }
}
