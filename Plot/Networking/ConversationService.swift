//
//  ConversationService.swift
//  Plot
//
//  Created by Cory McHattie on 12/24/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Foundation
import Firebase

class ConversationService {
    let conversationsFetcher = ConversationsFetcher()
    
    var conversations = [Conversation]()
    
    init() {
        conversationsFetcher.delegate = self
        
    }
    
    func grabConversations() {
        DispatchQueue.global(qos: .default).async { [unowned self] in
            conversationsFetcher.fetchConversations()
        }
    }
}

extension ConversationService: ConversationUpdatesDelegate {
    func conversations(didStartFetching: Bool) {
        
    }
    
    func conversations(didStartUpdatingData: Bool) {
        
    }
    
    func conversations(didFinishFetching: Bool, conversations: [Conversation]) {
        self.conversations = conversations
        
    }
    
    func conversations(update conversation: Conversation, reloadNeeded: Bool) {
        let chatID = conversation.chatID ?? ""
        
        if let index = conversations.firstIndex(where: {$0.chatID == chatID}) {
            conversations[index] = conversation
        }
    }
}
