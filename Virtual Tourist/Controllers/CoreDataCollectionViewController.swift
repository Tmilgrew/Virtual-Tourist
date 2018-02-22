//
//  CoreDataCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Thomas Milgrew on 1/29/18.
//  Copyright © 2018 Thomas Milgrew. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class CoreDataCollectionViewController: UICollectionViewController {
    
    // MARK: Properties
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the table
            fetchedResultsController?.delegate = self as? NSFetchedResultsControllerDelegate
            executeSearch()
            collectionView?.reloadData()
        }
    }
    
    // MARK: Initializers
    init(fetchedResultsController fc : NSFetchedResultsController<NSFetchRequestResult>, collectionViewLayout layout: UICollectionViewLayout) {
        fetchedResultsController = fc
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

// MARK: - CoreDataTableViewController (Table Data Source)

extension CoreDataCollectionViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /*
         TODO: Implement this method.  Item selected should be highlighted and added to a list of photos in queue to delete.
         */
    }
    
}


// MARK: - CoreDataCollectionViewController (Fetches)

extension CoreDataCollectionViewController {
    
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))")
            }
        }
    }
}
