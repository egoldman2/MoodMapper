//
//  AuthenticationService.swift
//  MoodMapper
//
//  Created by Ethan on 5/10/2025.
//

import Foundation
import FirebaseAuth
import Combine

final class AuthenticationService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isAnonymous = false
    @Published var isLoading = true
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                self?.isAnonymous = user?.isAnonymous ?? false
                self?.isLoading = false
                
                print("🔐 Auth state changed - Authenticated: \(self?.isAuthenticated ?? false), Anonymous: \(self?.isAnonymous ?? false)")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            print("🔐 User signed out")
        } catch {
            print("❌ Failed to sign out: \(error)")
        }
    }
    
    func deleteAccount() {
        guard let user = currentUser else { return }
        
        user.delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Failed to delete account: \(error)")
                } else {
                    print("✅ Account deleted successfully")
                    self?.isAuthenticated = false
                    self?.currentUser = nil
                    self?.isAnonymous = false
                }
            }
        }
    }
    
    var canSync: Bool {
        return isAuthenticated && !isAnonymous
    }
}
