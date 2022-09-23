//	
// Copyright © Essential Developer. All rights reserved.
//

import UIKit

enum Formatters {
	static var date = DateFormatter()
	static var number = NumberFormatter()
}

extension UIViewController {
	var presenterVC: UIViewController {
		parent?.presenterVC ?? parent ?? self
	}
}

extension DispatchQueue {
	static func mainAsyncIfNeeded(execute work: @escaping () -> Void) {
		if Thread.isMainThread {
			work()
		} else {
			main.async(execute: work)
		}
	}
}

extension UIViewController {
    func showAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        showDetailViewController(alert, sender: self)
    }
    
    @objc func addCard() {
        show(AddCardViewController(), sender: self)
    }
    
    @objc func addFriend() {
        show(AddFriendViewController(), sender: self)
    }
    
    @objc func sendMoney() {
        show(SendMoneyViewController(), sender: self)
    }
    
    @objc func requestMoney() {
        show(RequestMoneyViewController(), sender: self)
    }
    
    func showFriend(friend: Friend) {
        let vc = FriendDetailsViewController()
        vc.friend = friend
        show(vc, sender: self)
    }
    
    func showCard(card: Card) {
        let vc = CardDetailsViewController()
        vc.card = card
        show(vc, sender: self)
    }
    
    func showTransfer(transfer: Transfer) {
        let vc = TransferDetailsViewController()
        vc.transfer = transfer
        show(vc, sender: self)
    }
}


extension UITableViewCell {
    func configure(item: ItemListViewModel) {
        self.textLabel?.text = item.title
        self.detailTextLabel?.text = item.subtitle
    }
}

protocol ItemService {
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void)
}


struct FriendsAPIItemServiceAdapter: ItemService {
    let api: FriendsAPI
    let cache: FriendsCache
    let select: (Friend) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        api.loadFriends { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion( result.map { items in
                    cache.save(items)
                    return items.map{ item in
                        ItemListViewModel(friend: item) {
                            select(item)
                        }
                    }
                })
            }
        }
    }
}

struct FriendsCacheItemServiceAdapter: ItemService {
    let cache: FriendsCache
    let select: (Friend) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        cache.loadFriends { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion( result.map { items in
                    items.map{ item in
                        ItemListViewModel(friend: item) {
                            select(item)
                        }
                    }
                })
            }
        }
    }
}

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

struct ReceivedTransfersAPIItemServiceAdapter: ItemService {
    let api: TransfersAPI
    let select: (Transfer) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        api.loadTransfers { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion( result.map ({ transfers in
                    transfers.filter({
                        !$0.isSender
                    }) .map({ transfer in
                        ItemListViewModel(transfer: transfer, longDateStyle: false, selection: {
                            select(transfer)
                        })
                    })
                }))
            }
        }
    }
}

struct SentTransfersAPIItemServiceAdapter: ItemService {
    let api: TransfersAPI
    let select: (Transfer) -> Void
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        api.loadTransfers { result in
            DispatchQueue.mainAsyncIfNeeded {
                completion( result.map ({ transfers in
                    transfers.filter({
                        $0.isSender
                    }) .map({ transfer in
                        ItemListViewModel(transfer: transfer, longDateStyle: true, selection: {
                            select(transfer)
                        })
                    })
                }))
            }
        }
    }
}

//Null object pattern
class NullFriendsCache: FriendsCache {
    override func save(_ newFriends: [Friend]) {}
}

extension ItemService {
    func fallback(_ fallback: ItemService) -> ItemService {
        ItemServiceWithFallback(primary: self, fallback: fallback)
    }
    
    func retry(_ retryCount: UInt) -> ItemService {
        var service: ItemService = self
        for _ in 0..<retryCount {
            service = service.fallback(self)
        }
        return service
    }
}

struct ItemServiceWithFallback: ItemService {
    let primary: ItemService
    let fallback: ItemService
    
    func loadItems(completion: @escaping (Result<[ItemListViewModel], Error>) -> Void) {
        primary.loadItems { result in
            switch result {
            case .success:
                completion(result)
            case .failure:
                fallback.loadItems(completion: completion)
            }
        }
    }
}
