//	
// Copyright © Essential Developer. All rights reserved.
//

import Foundation

struct CardsAPIItemServiceAdapter: ItemService {
    let api: CardAPI
    let select: (Card) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        api.loadCards { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion( result.map ({ cards in
                    cards.map({ card in
                        ItemListViewModel(card: card, selection: {
                            select(card)
                        })
                    })
                }))
            }
        }
    }
}
