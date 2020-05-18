//
//  WeatherRow.swift
//  Plot
//
//  Created by Cory McHattie on 4/28/20.
//  Copyright © 2020 Immature Creations. All rights reserved.
//

import Eureka
import UIKit

final class WeatherCell: Cell<[DailyWeatherElement]>, CellType, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    var weather: [DailyWeatherElement]?
    
    private let kWeatherCollectionViewCell = "WeatherCollectionViewCell"
        
    public lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: self.contentView.frame.width, height: self.contentView.frame.height), collectionViewLayout: self.collectionViewLayout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(WeatherCollectionViewCell.self, forCellWithReuseIdentifier: kWeatherCollectionViewCell)
        return collectionView
    }()
    
    public var collectionViewLayout: UICollectionViewLayout = {
        var layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        return layout
    }()
    
    let activityIndicatorView: UIActivityIndicatorView = {
        let aiv = UIActivityIndicatorView(style: .white)
        aiv.color = .darkGray
        aiv.startAnimating()
        aiv.hidesWhenStopped = true
        return aiv
    }()
    
    override func setup() {
        super.setup()
        height = { 130 }
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(activityIndicatorView)
        activityIndicatorView.centerInSuperview()
        
        
    }
    
    override func update() {
        // we do not want to show the default UITableViewCell's textLabel
        textLabel?.text = nil
        
        contentView.addSubview(collectionView)

        if let weather = row.value {
            activityIndicatorView.stopAnimating()
            self.weather = weather
        }
        
    }
    
    func reload() {
        collectionView.reloadData()
    }
            
    //MARK: UICollectionViewDelegate and Datasource
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weather?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: kWeatherCollectionViewCell, for: indexPath) as! WeatherCollectionViewCell
        let dailyWeather = weather?[indexPath.item]
        cell.weather = dailyWeather
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 80, height: contentView.frame.height)

        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {

        //Where elements_count is the count of all your items in that
        //Collection view...
        let cellCount = CGFloat(weather?.count ?? 0)

        //If the cell count is zero, there is no point in calculating anything.
        if cellCount > 0 {
            let totalCellWidth = 80 * cellCount
            let contentWidth = collectionView.frame.size.width - collectionView.contentInset.left - collectionView.contentInset.right

            if (totalCellWidth < contentWidth) {
                //If the number of cells that exists take up less room than the
                //collection view width... then there is an actual point to centering them.

                //Calculate the right amount of padding to center the cells.
                let padding = (contentWidth - totalCellWidth) / 2.0
                return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
            } else {
                //Pretty much if the number of cells that exist take up
                //more room than the actual collectionView width, there is no
                // point in trying to center them. So we leave the default behavior.
                return UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
            }
        }
        return UIEdgeInsets.zero
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}

final class WeatherRow: Row<WeatherCell>, RowType {
    required init(tag: String?) {
        super.init(tag: tag)
    }
}

class WeatherCollectionViewCell: UICollectionViewCell {
    
    var weather: DailyWeatherElement! {
        didSet {
            if let dateString = weather.observationTime?.value, let date = dateString.toDate() {
                if Calendar.current.isDateInToday(date) {
                    dayLabel.text = "Today"
                } else if Calendar.current.isDateInTomorrow(date) {
                    dayLabel.text = "Tomorrow"
                } else {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEE"
                    dayLabel.text = formatter.string(from: date)
                }
            }
            if let temp = weather.temp {
                if let min = temp[0].min, let minValue = min.value {
                    minLabel.text = "\(Int(minValue))°"
                }
                if let max = temp[1].max, let maxValue = max.value {
                    maxLabel.text = "\(Int(maxValue))°"
                }
            }
            if let weatherTypeDict = weather.weatherCode, let weatherType = weatherTypeDict.value {
                weatherImageView.image = UIImage(named: weatherType.image)
            }
            setupViews()
        }
    }
        
    
    let dayLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.isUserInteractionEnabled = false
        label.textAlignment = .center
        return label
    }()
    
    let maxLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.isUserInteractionEnabled = false
        label.textAlignment = .center
        return label
    }()
    
    let minLabel: UILabel = {
        let label = UILabel()
        label.textColor = ThemeManager.currentTheme().generalTitleColor
        label.font = UIFont.preferredFont(forTextStyle: .body)
        label.isUserInteractionEnabled = false
        label.textAlignment = .center
        return label
    }()
    
    let weatherImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }()
        
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        
        weatherImageView.constrainHeight(constant: 40)
        
        let stackView = VerticalStackView(arrangedSubviews: [
            dayLabel,
            maxLabel,
            minLabel,
            weatherImageView,
            ], spacing: 1)
        addSubview(stackView)
        stackView.distribution = .equalCentering
        stackView.fillSuperview(padding: .init(top: 0, left: 0, bottom: 0, right: 0))

        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dayLabel.text = nil
        maxLabel.text = nil
        minLabel.text = nil
        weatherImageView.image = nil

    }
    
}
