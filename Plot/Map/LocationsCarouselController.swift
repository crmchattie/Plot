//
//  LocationsCarouselController.swift
//  MapsDirectionsGooglePlaces_LBTA
//
//  Created by Brian Voong on 11/6/19.
//  Copyright © 2019 Brian Voong. All rights reserved.
//

import UIKit
import LBTATools
import MapKit

struct LocationStruct {
    var name: String
    var address: String
    var type: String
    var category: String?
    var subcategory: String?
    var lat: Double
    var lon: Double
    
    init(name: String, address: String, type: String, category: String, subcategory: String, lat: Double, lon: Double) {
        self.name = name
        self.address = address
        self.type = type
        self.category = category
        self.subcategory = subcategory
        self.lat = lat
        self.lon = lon
    }
}

class LocationCell: LBTAListCell<LocationStruct> {
    
    override var item: LocationStruct! {
        didSet {
            nameLabel.text = item.name
            addressLabel.text = item.address
            categoryLabel.text = item.category
            let numberOfLines = nameLabel.numberOfVisibleLines - 1
            if numberOfLines > 1 {
                subcategoryLabel.text = ""
            } else if item.subcategory!.isEmpty && numberOfLines < 2 {
                subcategoryLabel.text = " "
            } else {
                subcategoryLabel.text = item.subcategory
            }
            typeButton.setImage(UIImage(named: item.type), for: .normal)
        }
    }
    
    let nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    
    let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let categoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let subcategoryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = ThemeManager.currentTheme().generalSubtitleColor
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()
    
    let typeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "activity"), for: .normal)
        button.isUserInteractionEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    let view: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    
    override func setupViews() {
                
        typeButton.constrainWidth(30)
        typeButton.constrainHeight(30)
        
        backgroundColor = ThemeManager.currentTheme().cellBackgroundColor
        
        setupShadow(opacity: 0.2, radius: 5, offset: .zero, color: .black)
        layer.cornerRadius = 5
        
        view.addSubview(nameLabel)
        view.addSubview(typeButton)
        nameLabel.anchor(top: view.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: typeButton.leadingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
        typeButton.anchor(top: view.topAnchor, leading: nil, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 0, bottom: 0, right: 0))
                
        stack(view, addressLabel, categoryLabel, subcategoryLabel, spacing: 2).withMargins(.init(top: 10, left: 16, bottom: 10, right: 16))
        

    }
}

class LocationsCarouselController: LBTAListController<LocationCell, LocationStruct> {
    
    weak var mapViewController: MapViewController?
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let annotations = mapViewController?.mapView.annotations
        
        annotations?.forEach({ (annotation) in
            if annotation.title == self.items[indexPath.item].name {
                mapViewController?.mapView.selectAnnotation(annotation, animated: true)
            }
        })
        
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.clipsToBounds = false
        collectionView.backgroundColor = .clear
    }
}

extension LocationsCarouselController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 32, bottom: 0, right: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: view.frame.width - 64, height: view.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
}
