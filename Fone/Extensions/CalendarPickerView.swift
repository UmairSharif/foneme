//
//  CalendarPickerView.swift
//  TCBSCd
//
//  Created by Dong IT. Nguyen Van on 15/03/2023.
//

import UIKit
import SnapKit

public enum CalendarPickerTransitionType {
    case modal
    case push
}

public protocol CalendarPickerViewDelegate: AnyObject {
    func didSelectedDate(_ date: Date)
    func changeMonth(_ isPrev: Bool, date: Date)
    func didReloadData(_ contentHeight: CGFloat)
    func didSelectDisableDate(_ date: Date?)
}

public class CalendarPickerView: UIView {

    private var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var stackView: UIStackView = {
       let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 24
        return stack
    }()
    
    private lazy var monthStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        return stack
    }()
    
    private lazy var prevButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "small-left"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "small-right"), for: .normal)
        button.tintColor = .white
        return button
    }()
    
    private lazy var monthButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(UIColor(named: "f5F5F5"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        return button
    }()
        
    private lazy var cellSize: CGSize = {
        let padding: CGFloat = 80
        let spacing: CGFloat = CGFloat(2 * titles.count)
        let minWidth: CGFloat = 20
        let screenWidth = UIScreen.main.bounds.width
        let calWidth = (screenWidth - padding - spacing) / CGFloat(titles.count)
        let width = max(minWidth, calWidth)
        let height = width
        return CGSize(width: width, height: height)
    }()
    
    private lazy var collectionView: AutoSizingCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = cellSize
        layout.minimumLineSpacing = 2
        layout.minimumInteritemSpacing = 2
        layout.sectionInset = UIEdgeInsets(top: 0, left: 24, bottom: 0, right: 24)
        let collectionView = AutoSizingCollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        return collectionView
    }()
    
    public weak var delegate: CalendarPickerViewDelegate?
    private var type: CalendarPickerTransitionType = .modal
    
    private var titles: [String] = []
    private var currentDate: Date = Date() {
        didSet {
            monthButton.setTitle(currentDate.getHeaderTitleFC(), for: .normal)
            daysInMonth = currentDate.getDaysInMonthFC()
            startDayOfMonth = currentDate.startOfMonthFC()
            weekDayOfStart = startDayOfMonth.getDayOfWeekFC() ?? 0
            indexOfWeekday = (weekDayOfStart == 1 ? 7 : (weekDayOfStart + 6) % 7) - 1
            checkIsEnableButton()
            collectionView.reloadData()
//            delegate?.didReloadData(calculateHeight())
        }
    }
    
    private var maxDate: Date? {
        didSet {
            checkIsEnableButton()
            collectionView.reloadData()
        }
    }
    
    private var minDate: Date? {
        didSet {
            checkIsEnableButton()
            collectionView.reloadData()
        }
    }
    
    private var selectedDate: Date? {
        didSet {
            collectionView.reloadData()
//            delegate?.didReloadData(calculateHeight())
        }
    }

    private lazy var daysInMonth = currentDate.getDaysInMonthFC()
    
    private lazy var startDayOfMonth = currentDate.startOfMonthFC()
    
    private lazy var weekDayOfStart = startDayOfMonth.getDayOfWeekFC() ?? 0
    
    private lazy var indexOfWeekday = (weekDayOfStart == 1 ? 7 : (weekDayOfStart + 6) % 7) - 1
    
    private var heightCollectionView: Constraint?
    
    init(type: CalendarPickerTransitionType) {
        self.type = type
        super.init(frame: .zero)
        configureViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureViews()
    }
    
    public func setCurrentDate(_ date: Date?) {
        if let date = date {
            self.currentDate = date
        }
    }
    
    public func setMaxDate(_ date: Date) {
        self.maxDate = date
    }
    
    public func setMinDate(_ date: Date) {
        self.minDate = date
    }
    
    public func setDefaultSelectedDate(_ date: Date) {
        self.selectedDate = date
    }
    
    @objc private func handleChangeMonth(_ sender: UIButton) {
        
        if sender == prevButton {
            if let prevDate = self.currentDate.date(byAdding: .month, value: -1) {
                self.currentDate = prevDate
                delegate?.changeMonth(true, date: prevDate)
            }
        } else if sender == nextButton {
            if let nextDate = self.currentDate.date(byAdding: .month, value: 1) {
                self.currentDate = nextDate
                delegate?.changeMonth(false, date: nextDate)
            }
        }
    }
    
    private func configureViews() {
        
        self.titles = prepareWeekdaySymbols()
        
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.left.bottom.right.equalToSuperview()
        }
        containerView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
        }
        
        stackView.addArrangedSubviews([monthStackView, collectionView])
        monthStackView.addArrangedSubviews([prevButton, monthButton, nextButton])
        monthStackView.snp.makeConstraints { make in
            make.height.equalTo(25)
        }
        prevButton.snp.makeConstraints({ $0.width.equalTo(72) })
        nextButton.snp.makeConstraints({ $0.width.equalTo(72) })
        
        setupCollectionView()
        
        prevButton.addTarget(self, action: #selector(handleChangeMonth(_:)), for: .touchUpInside)
        
        nextButton.addTarget(self, action: #selector(handleChangeMonth(_:)), for: .touchUpInside)
        
        monthButton.setTitle(currentDate.getHeaderTitleFC(), for: .normal)
    }
    
    private func calculateHeight() -> CGFloat {
//        let maxDay = daysInMonth + indexOfWeekday
//        let rows = (CGFloat(maxDay) / 7).rounded(.up)
        // Fixed max 7 rows
        let rows: CGFloat = 7
        let height = cellSize.height * (rows + 1) + (rows - 1) * 6
        let headerHeight: CGFloat = 25
        return height + headerHeight
    }
    
    private func setupCollectionView() {
        collectionView.register(UINib(nibName: "DatePickerCell", bundle: Bundle(for: DatePickerCell.self)), forCellWithReuseIdentifier: "DatePickerCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.reloadData()
        delegate?.didReloadData(calculateHeight())
    }
    
    private func checkIsValid(date: Date) -> Bool {
        
        var isValidMax = false
        var isValidMin = false
        
        if let min = self.minDate {
            isValidMin = date.compare(to: min) != .orderedAscending
        } else {
            isValidMin = true
        }
        
        if let max = self.maxDate {
            isValidMax = date.compare(to: max) != .orderedDescending
        } else {
            isValidMax = true
        }
        
        return isValidMin && isValidMax
    }
    
    private func checkIsEnableButton() {
        if let min = self.minDate {
            let isEnable = currentDate.compareMonth(to: min) < 0
            self.prevButton.isEnabled = isEnable
        }
        
        if let max = self.maxDate {
            let isEnable = currentDate.compareMonth(to: max) > 0
            self.nextButton.isEnabled = isEnable
        }
    }
    
    private func prepareWeekdaySymbols() -> [String] {
        let calendar = Calendar.current
        var symbols = calendar.shortWeekdaySymbols
        
        guard !symbols.isEmpty else { return [] }
        let sun = symbols[0]
        symbols.removeFirst()
        symbols.append(sun)
        return symbols
    }
}

extension CalendarPickerView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    enum CalendarPickerSection: Int, CaseIterable {
        case title
        case day
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let calendarPickerSections = CalendarPickerSection(rawValue: indexPath.section)!
        guard calendarPickerSections == .day else {
            return
        }
        let index = indexPath.row + 1
        let maxDay = daysInMonth + indexOfWeekday
        let day = index - indexOfWeekday
        if index <= maxDay && day > 0, let date = currentDate.setTime(day: day), checkIsValid(date: date) {
            self.selectedDate = date
            delegate?.didSelectedDate(date)
        } else {
            let date = currentDate.setTime(day: day)
            delegate?.didSelectDisableDate(date)
        }
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return CalendarPickerSection.allCases.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let calendarPickerSections = CalendarPickerSection(rawValue: section)!
        switch calendarPickerSections {
        case .title:
            return titles.count
        case .day:
            return indexOfWeekday + daysInMonth
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DatePickerCell",
                                                            for: indexPath) as? DatePickerCell else {
            return UICollectionViewCell()
        }
        guard let calendarPickerSections = CalendarPickerSection(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }

        switch calendarPickerSections {
        case .title:
            let isWeekend = indexPath.row == titles.count - 1 || indexPath.row == titles.count - 2
            cell.bind(.title, title: titles[indexPath.row], isWeekend: isWeekend,
                      isSelect: false, isEnable: true)
            cell.selectBackgroundView.layer.cornerRadius = 0
        case .day:
            var isEnable = false
            let index = indexPath.row + 1
            let maxDay = daysInMonth + indexOfWeekday
            let day = index - indexOfWeekday
            
            if index <= maxDay && day > 0, let date = currentDate.setTime(day: day, hour: 9, min: 0) {
                
                let isWeekend = Calendar.current.isDateInWeekend(date)
                isEnable = checkIsValid(date: date)
                var isSelect = false
                if let selectDate = self.selectedDate {
                    isSelect = Calendar.current.isDate(date, inSameDayAs: selectDate)
                }
                cell.bind(.day, title: "\(day)", isWeekend: isWeekend,
                          isSelect: isSelect, isEnable: isEnable)
            } else {
                cell.bind(.day, title: "", isWeekend: false,
                          isSelect: false, isEnable: false)
            }
            cell.selectBackgroundView.layer.cornerRadius = cellSize.width / 2
        }

        return cell
    }
}

extension UICollectionView {
    /// Registers a nib or a UICollectionViewCell object containing a cell
    /// with the collection view under a specified identifier.
    func register<T: UICollectionViewCell>(_ aClass: T.Type, bundle: Bundle? = .main) {
        let name = String(describing: aClass)
        if bundle?.path(forResource: name, ofType: "nib") != nil {
            let nib = UINib(nibName: name, bundle: bundle)
            register(nib, forCellWithReuseIdentifier: name)
        } else {
            register(aClass, forCellWithReuseIdentifier: name)
        }
    }

    /// Returns a reusable collection-view cell object located by its identifier.
    func dequeue<T: UICollectionViewCell>(_ aClass: T.Type, indexPath: IndexPath) -> T {
        let name = String(describing: aClass)
        guard let cell = dequeueReusableCell(withReuseIdentifier: name, for: indexPath) as? T else {
            fatalError("`\(name)` is not registered")
        }
        return cell
    }
}

class AutoSizingCollectionView: UICollectionView {
    var maxHeight: CGFloat = UIScreen.main.bounds.height {
        didSet {
            guard oldValue != maxHeight else { return }
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        let height = min(maxHeight, contentSize.height)
        return CGSize(width: contentSize.width, height: height)
    }
}

extension Date {
    
    func getDaysInMonthFC() -> Int {
        let calendar = Calendar.current
        
        let dateComponents = DateComponents(year: calendar.component(.year, from: self), month: calendar.component(.month, from: self))
        let date = calendar.date(from: dateComponents)!
        
        let range = calendar.range(of: .day, in: .month, for: date)!
        let numDays = range.count
        
        return numDays
    }
    
    func startOfMonthFC() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    
    func endOfMonthFC() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonthFC())!
    }
    
    func getDayOfWeekFC() -> Int? {
        let myCalendar = Calendar(identifier: .gregorian)
        let weekDay = myCalendar.component(.weekday, from: self)
        return weekDay
    }
    
    func getHeaderTitleFC() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.locale = .current
        dateFormatter.dateFormat = "MMM YYYY"
        return dateFormatter.string(from: self)
    }
    
    func getDayFC(day: Int) -> Date {
        let day = Calendar.current.date(byAdding: .day, value: day, to: self)!
        return Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: day)!
    }
    
    func getMonthOnlyFC() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        return dateFormatter.string(from: self)
    }
    
    func getYearOnlyFC() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY"
        return dateFormatter.string(from: self)
    }
    
    func getHour() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh"
        return dateFormatter.string(from: self)
    }
    
    func getTitleDateFC() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, MMM dd"
        return dateFormatter.string(from: self)
    }
    
    func setDate(date: Int) -> Date {
        
        let  x: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let cal = Calendar.current
        var component = cal.dateComponents(x, from: self)
        component.day = date
        return cal.date(from: component)!
    }
}

extension Date {
    
    func addMonthFC(month: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: month, to: self)!
    }
    
    func fullDistance(from date: Date = Date()) -> Double {
        
        let timeInterval = self.timeIntervalSince1970
        let now = date.timeIntervalSince1970
        
        return (now - timeInterval) / 3600
    }
    
    func distance(from date: Date, only component: Calendar.Component, calendar: Calendar = .current) -> Int {
        let days1 = calendar.component(component, from: self)
        let days2 = calendar.component(component, from: date)
        return days1 - days2
    }
    
    func hasSame(_ component: Calendar.Component, as date: Date) -> Bool {
        distance(from: date, only: component) == 0
    }
    
    func compare(to date: Date) -> ComparisonResult {
        var calendar = Calendar.current
        calendar.timeZone = .current
        // Replace the hour (time) of both dates with 00:00
        guard let date1 = self.setTime(hour: 9, min: 0),
              let date2 = date.setTime(hour: 9, min: 0) else {
            return .orderedSame
        }
        
        return date1.compare(date2)
    }
    
    func compareMonth(to date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        // Replace the hour (time) of both dates with 00:00
        guard let date1 = calendar.startOfDay(for: self).setTime(day: 1),
              let date2 = calendar.startOfDay(for: date).setTime(day: 1) else {
            return 0
        }
                
        let components = calendar.dateComponents([.month], from: date1, to: date2)
        return components.month ?? 0
    }
    
    func compareDay(to date: Date) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = .current
        // Replace the hour (time) of both dates with 00:00
        guard let date1 = self.setTime(hour: 9, min: 0),
              let date2 = date.setTime(hour: 9, min: 0) else {
            return -1
        }
        
        guard date1.compare(date2) != .orderedDescending else {
            return -1
        }
                
        let components = calendar.dateComponents([.day], from: date1, to: date2)
        return components.day ?? -1
    }
    
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }

    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    
    func setTime(day: Int, hour: Int, min: Int) -> Date? {
        let x: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let cal = Calendar.current
        let component = cal.dateComponents(x, from: self)
        var dateComponents = DateComponents()
        dateComponents.year = component.year
        dateComponents.month = component.month
        dateComponents.day = day
        dateComponents.timeZone = TimeZone(secondsFromGMT: 7)
        dateComponents.hour = hour
        dateComponents.minute = min
        let someDateTime = cal.date(from: dateComponents)
        return someDateTime
      }
    
    func setTime(hour: Int, min: Int) -> Date? {
        let x: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        let cal = Calendar.current
        let component = cal.dateComponents(x, from: self)
        var dateComponents = DateComponents()
        dateComponents.year = component.year
        dateComponents.month = component.month
        dateComponents.day = component.day
        dateComponents.timeZone = TimeZone(secondsFromGMT: 7)
        dateComponents.hour = hour
        dateComponents.minute = min
        let someDateTime = cal.date(from: dateComponents)
        return someDateTime
      }

}

extension Date {
    func setTime(day: Int) -> Date? {
        
        let  x: Set<Calendar.Component> = [.hour, .minute, .second]
        var cal = Calendar.current
        cal.timeZone = .current
        var component = cal.dateComponents(x, from: self)
        component.day = day
        component.year = self.year()
        component.month = self.month()
        return cal.date(from: component)
    }
    func date(byAdding component: Calendar.Component, value: Int, inCalendar calendar: Calendar = .current) -> Date? {
        return calendar.date(byAdding: component, value: value, to: self)
    }
    func year(calendar: Calendar = .current) -> Int? {
        return calendar.dateComponents([.year], from: self).year
    }
    func month(calendar: Calendar = .current) -> Int? {
        return calendar.dateComponents([.month], from: self).month
    }
}

extension Date {
    func isBetween(date1: Date, date2: Date) -> Bool {
        return (min(date1, date2) ... max(date1, date2)).contains(self)
//        return date1.compare(self).rawValue * self.compare(date2).rawValue >= 0
    }

    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    // swiftlint:disable:next colon
    var millisecondsSince1970:Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    // swiftlint:disable:next colon
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
// Convenience way to add multiple subviews at one time
public extension UIStackView {
    
    func addArrangedSubviews<S: Sequence>(_ subviews: S) where S.Iterator.Element: UIView {
        subviews.forEach(self.addArrangedSubview(_:))
    }
    
    func addArrangedSubviews(_ subviews: UIView...) {
        self.addArrangedSubviews(subviews)
    }
    
}
