//
//  LGV_Timer_TimerSetController.swift
//  LGV_Timer
//
//  Created by Chris Marshall on 5/24/17.
//  Copyright © 2017 Little Green Viper Software Development LLC. All rights reserved.
//
/* ###################################################################################################################################### */
/**
 */

import UIKit

/* ###################################################################################################################################### */
/**
 */
class LGV_Timer_TimerSetController: LGV_Timer_TimerSetPickerController {
    static let switchToSettingsSegueID = "timer-segue-to-settings"
    static let startTimerSegueID = "timer-segue-to-start-timer"
    
    @IBOutlet weak var startButton: UIBarButtonItem!
    @IBOutlet weak var setupButton: UIBarButtonItem!
    @IBOutlet weak var timeSetLabel: UILabel!
    @IBOutlet weak var setTimePickerView: UIPickerView!
    @IBOutlet weak var timerModeSegmentedSwitch: UISegmentedControl!
    
    var dontBotherTheWatch: Bool = false
    var runningTimer: LGV_Timer_TimerRuntimeViewController! = nil
    
    // MARK: - Internal @IBAction Methods
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     Bring in the setup screen button hit.
     */
    @IBAction func setupButtonHit(_ sender: Any) {
        self.bringInSettingsScreen()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func startButtonHit(_ sender: Any) {
        LGV_Timer_AppDelegate.appDelegateObject.timerEngine.startTimer()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func modeSegmentedControlChanged(_ sender: UISegmentedControl) {
        self.timerObject.displayMode = TimerDisplayMode(rawValue: sender.selectedSegmentIndex)!
    }
    
    // MARK: - Internal Instance Methods
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     Bring in the setup screen.
     */
    func bringInSettingsScreen() {
        self.performSegue(withIdentifier: type(of:self).switchToSettingsSegueID, sender: nil)
    }
    
    /* ################################################################## */
    /**
     Start the Timer.
     */
    func startTimer() {
        self.performSegue(withIdentifier: type(of:self).startTimerSegueID, sender: nil)
    }
    
    /* ################################################################## */
    /**
     */
    private func _setUpDisplay() {
        if nil != self.startButton {
            self.startButton.isEnabled = 0 < self.timerObject.timeSet
        }
        
        let timerNumber = self.timerNumber
        let tabBarImage = self.tabBarImage
        
        if let _ = self.navigationController as? LGV_Timer_TimerNavController {
            self.tabBarController?.viewControllers?[timerNumber + 1].tabBarItem.image = tabBarImage
            self.tabBarController?.viewControllers?[timerNumber + 1].tabBarItem.selectedImage = tabBarImage
        }
    }
    
    /* ################################################################## */
    /**
     */
    func updateTimer() {
        let timeSet = TimeTuple(self.timerObject.timeSet)
        
        if nil != self.setTimePickerView {
            self.setTimePickerView.reloadAllComponents()
            self.setTimePickerView.selectRow(timeSet.hours, inComponent: Components.Hours.rawValue, animated: true)
            self.setTimePickerView.selectRow(timeSet.minutes, inComponent: Components.Minutes.rawValue, animated: true)
            self.setTimePickerView.selectRow(timeSet.seconds, inComponent: Components.Seconds.rawValue, animated: true)
        }
        
        self._setUpDisplay()
        
        if nil != self.runningTimer {
            if (.Stopped == self.timerObject.timerStatus) || (.Invalid == self.timerObject.timerStatus) {
                self.navigationController?.popViewController(animated: true)
            } else {
                self.runningTimer.updateTimer()
            }
        }
    }
    
    // MARK: - Base Class Override Methods
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     Called when the view has finished loading.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dontBotherTheWatch = false
        
        if let tabber = self.tabBarController as? LGV_Timer_MainTabController {
            tabber.addTimerToList(self)
        }
        
        for segment in 0..<self.timerModeSegmentedSwitch.numberOfSegments {
            self.timerModeSegmentedSwitch.setTitle(self.timerModeSegmentedSwitch.titleForSegment(at: segment)?.localizedVariant, forSegmentAt: segment)
        }
        
        self.setupButton.title = self.setupButton.title?.localizedVariant
        self.timeSetLabel.text = self.timeSetLabel.text?.localizedVariant
    }
    
    /* ################################################################## */
    /**
     Called when the view will display.
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let navBar = self.navigationController?.navigationBar {
            let titleColor = LGV_Timer_AppDelegate.appDelegateObject.timerEngine.colorLabelArray[self.timerObject.colorTheme].textColor!
            navBar.titleTextAttributes?[NSAttributedStringKey.foregroundColor.rawValue] = titleColor
        }
        
        self.timerModeSegmentedSwitch.selectedSegmentIndex = self.timerObject.displayMode.rawValue
        self.updateTimer()
        if !self.dontBotherTheWatch {
            LGV_Timer_AppDelegate.appDelegateObject.sendSelectMessage(timerUID: self.timerObject.uid)
        }
        
        self.dontBotherTheWatch = false
    }
    
    /* ################################################################## */
    /**
     Called when the view will go away.
     */
    override func viewWillDisappear(_ animated: Bool) {
        if let navBar = self.navigationController?.navigationBar {
            navBar.titleTextAttributes?[NSAttributedStringKey.foregroundColor.rawValue] = UIColor.white
        }
    }
    
    /* ################################################################## */
    /**
     Called when the view has finished displaying.
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.updateTimer()
    }
    
    /* ################################################################## */
    /**
     Called when we are about to bring in the setup controller.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        self.dontBotherTheWatch = true
        if let destinationController = segue.destination as? LGV_Timer_TimerRuntimeViewController {
            destinationController.myHandler = self
            self.runningTimer = destinationController
        }
        
        if let destinationController = segue.destination as? LGV_Timer_TimerNavBaseController {
            destinationController.timerObject = self.timerObject
        }
    }
    
    /// MARK: - UIPickerViewDelegate Methods
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let hours = pickerView.selectedRow(inComponent: Components.Hours.rawValue)
        let minutes = pickerView.selectedRow(inComponent: Components.Minutes.rawValue)
        let seconds = pickerView.selectedRow(inComponent: Components.Seconds.rawValue)
        self.timerObject.timeSet = Int(TimeTuple(hours: hours, minutes: minutes, seconds: seconds))
        self.updateTimer()
    }
}

