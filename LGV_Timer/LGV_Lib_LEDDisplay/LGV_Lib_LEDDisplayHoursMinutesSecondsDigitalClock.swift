//
//  LGV_Lib_LEDDisplayHoursMinutesSecondsDigitalClock.swift
//
//  Created by Chris Marshall on 5/23/17.
//  Copyright © 2017 Little Green Viper Software Development LLC. All rights reserved.
//
import UIKit
/* ###################################################################################################################################### */
/**
 This class instantiates a bunch of LED Elements into a "Digital Clock," to be displayed to cover most of the screen.
 */
public class LGV_Lib_LEDDisplayHoursMinutesSecondsDigitalClock : UIView {
    // MARK: - Instance Properties
    /* ################################################################################################################################## */
    var activeSegmentColor: UIColor = UIColor.green
    var inactiveSegmentColor: UIColor = UIColor.black
    var zeroPadding: Bool = false
    var separationSpace: Int = 16
    
    // In the following three properties (the time element values), we check to see if the value has changed. If so, we force a recalculation and display.
    var hours: Int = 0 {
        didSet {
            if self.hours != oldValue {
                self.setNeedsLayout()
            }
        }
    }
    var minutes: Int = 0 {
        didSet {
            if self.minutes != oldValue {
                self.setNeedsLayout()
            }
        }
    }
    var seconds: Int = 0 {
        didSet {
            if self.seconds != oldValue {
                self.setNeedsLayout()
            }
        }
    }
    
    // MARK: - Private Instance Properties
    /* ################################################################################################################################## */
    private var _separatorsOn: Bool = true                      ///< Whether or not the separators bewteen digit groups are shown.
    private var _allElementGroup: LED_ElementGrouping! = nil    ///< Used to pass the calculated paths to the draw method.
    private var _bottomLayer: CAShapeLayer! = nil               ///< Tracks the outline shapes for the segments (inactive)
    private var _topLayer: CAShapeLayer! = nil                  ///< Tracks the active ("lit") segment shapes.
    
    
    // MARK: - Private Class Methods
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     This will set an LED element grouping to display a value, in decimal numbering.
     
     :param: inGroup The LED element group that comprises one decimal number.
     :param: inValue The value to have the group display.
     :param: inZeroFill If true, we have leading zeroes displayed.
     */
    private class func _setDecimalValue(_ inGroup: LED_ElementGrouping, inValue: Int, inZeroFill: Bool) {
        let elements = inGroup.elements as! [LED_SingleDigit]
        
        var value = abs(inValue)
        
        var index = elements.count - 1
        
        while 0 < value {
            var digitValue = value
            if 9 < digitValue {
                digitValue -= (10 * Int(value / 10))
            }
            elements[index].value = digitValue
            value /= 10
            index -= 1
        }
        
        if inZeroFill {
            while 0 <= index {
                elements[index].value = 0
                index -= 1
            }
        } else {
            while 0 <= index {
                elements[index].value = -2
                index -= 1
            }
        }
    }
    
    // MARK: - Superclass Override Methods
    /* ################################################################################################################################## */
    /* ################################################################## */
    /**
     Called when the view needs to have its layout recalculated. Most of the work is done here.
     
     What we do, is establish the drawing UIBezierPaths for the inactive and active elements, then pass them to the draw method.
     The draw method then creates CALayers, and displays them, along with a brief animation, simulating a "gas flicker," as
     seen in old-time gas digital displays.
     */
    override public func layoutSubviews() {
        var hoursElementGroup: LED_ElementGrouping! = nil
        var minutesElementGroup: LED_ElementGrouping! = nil
        var secondsElementGroup: LED_ElementGrouping! = nil
        var secondsSeparatorElementGroup: LED_ElementGrouping! = nil
        var minutesSeparatorElementGroup: LED_ElementGrouping! = nil
        
        hoursElementGroup = LED_ElementGrouping(inElements: [LED_SingleDigit(-2), LED_SingleDigit(-2)], inContainerSize: CGSize.zero, inSeparationSpace: CGFloat(self.separationSpace))
        
        minutesSeparatorElementGroup = LED_ElementGrouping(inElements: [LED_SeparatorDots([true, true])], inContainerSize: CGSize.zero, inSeparationSpace: 0)
        minutesElementGroup = LED_ElementGrouping(inElements: [LED_SingleDigit(-2), LED_SingleDigit(-2)], inContainerSize: CGSize.zero, inSeparationSpace: CGFloat(self.separationSpace))

        secondsSeparatorElementGroup = LED_ElementGrouping(inElements: [LED_SeparatorDots([true, true])], inContainerSize: CGSize.zero, inSeparationSpace: 0)
        secondsElementGroup = LED_ElementGrouping(inElements: [LED_SingleDigit(-2), LED_SingleDigit(-2)], inContainerSize: CGSize.zero, inSeparationSpace: CGFloat(self.separationSpace))
        
        var elements: [LED_Element] = []
        
        if nil != hoursElementGroup {
            elements.append(hoursElementGroup)
        }
        
        if nil != minutesSeparatorElementGroup {
            elements.append(minutesSeparatorElementGroup)
        }
        
        if nil != minutesElementGroup {
            elements.append(minutesElementGroup)
        }
        
        if nil != secondsSeparatorElementGroup {
            elements.append(secondsSeparatorElementGroup)
        }
        
        if nil != secondsElementGroup {
            elements.append(secondsElementGroup)
        }
        
        if var size = LGV_Timer_AppDelegate.appDelegateObject.window?.bounds.size {
            size.height -= 40
            size.width -= 8
            
            self._allElementGroup = LED_ElementGrouping(inElements: elements, inContainerSize: size, inSeparationSpace: CGFloat(self.separationSpace))
        
            if nil != minutesSeparatorElementGroup {
                (minutesSeparatorElementGroup[0] as! LED_SeparatorDots).value = [self._separatorsOn, self._separatorsOn]
            }
            
            if nil != secondsSeparatorElementGroup {
                (secondsSeparatorElementGroup[0] as! LED_SeparatorDots).value = [self._separatorsOn, self._separatorsOn]
            }
            
            if nil != hoursElementGroup {
                type(of: self)._setDecimalValue(hoursElementGroup, inValue: self.hours, inZeroFill:  self.zeroPadding)
            }
            
            if nil != minutesElementGroup {
                let zeroPadding = (nil != hoursElementGroup) ? ((0 != self.hours) ? true : self.zeroPadding) : self.zeroPadding
                type(of: self)._setDecimalValue(minutesElementGroup, inValue: self.minutes, inZeroFill:  zeroPadding)
                
                if (0 == self.hours) && (!self.zeroPadding || (nil == hoursElementGroup)) && (nil != minutesSeparatorElementGroup) {
                    (minutesSeparatorElementGroup[0] as! LED_SeparatorDots).value = [false, false]
                }
            }
            
            if nil != secondsElementGroup {
                var zeroPadding = (nil != hoursElementGroup) ? ((0 != self.hours) ? true : self.zeroPadding) : self.zeroPadding
                zeroPadding = (nil != minutesElementGroup) ? ((0 != self.minutes) ? true : zeroPadding) : zeroPadding
                type(of: self)._setDecimalValue(secondsElementGroup, inValue: self.seconds, inZeroFill:   zeroPadding)
                
                if (0 == self.minutes) && (!zeroPadding || (nil == minutesElementGroup)) && (nil != secondsSeparatorElementGroup) {
                    (secondsSeparatorElementGroup[0] as! LED_SeparatorDots).value = [false, false]
                }
            }
        }
        
        super.layoutSubviews()
    }
    
    /* ################################################################## */
    /**
     In this drawing routine, we take each of the layers (the bottom, "inactive mask" layer, and the top, "active" layer),
     and render them, with a brief animation that makes a little "flare," as seen in the old gas elements.
     
     :param: rect the rectangle in which to render the display (ignored).
     */
    override public func draw(_ rect: CGRect) {
        let activePath = self._allElementGroup.activeSegments
        
        if nil != self._bottomLayer {
            self._bottomLayer.removeFromSuperlayer()
        }
        
        self._bottomLayer = CAShapeLayer()
        let inactivePath = self._allElementGroup.inactiveSegments
        inactivePath.append(activePath)
        self._bottomLayer.path = inactivePath.cgPath
        self._bottomLayer.strokeColor = UIColor.clear.cgColor
        self._bottomLayer.fillColor = self.inactiveSegmentColor.cgColor
        self.layer.addSublayer(self._bottomLayer)
        
        if nil != self._topLayer {
            self._topLayer.removeFromSuperlayer()
        }
        
        self._topLayer = CAShapeLayer()
        self._topLayer.strokeColor = UIColor.clear.cgColor
        self._topLayer.fillColor = self.activeSegmentColor.cgColor
        self._topLayer.path = activePath.cgPath
        
        let animation1 = CABasicAnimation(keyPath: "opacity")
        animation1.fromValue = 0.5
        animation1.toValue = 1.0
        animation1.duration = 0.025
        
        let animation2 = CABasicAnimation(keyPath: "opacity")
        animation2.beginTime = 0.025
        animation2.fromValue = 1.0
        animation2.toValue = 0.85
        animation2.duration = 0.15
        
        let animGroup: CAAnimationGroup = CAAnimationGroup()
        
        animGroup.animations = [animation1, animation2]
        
        self._topLayer.add(animGroup, forKey: "opacity")
        self._topLayer.opacity = 0.85
        
        self.layer.addSublayer(self._topLayer)
    }
}
