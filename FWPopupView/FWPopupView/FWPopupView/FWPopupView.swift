//
//  FWPopupView.swift
//  FWPopupView
//
//  Created by xfg on 2018/3/19.
//  Copyright © 2018年 xfg. All rights reserved.
//

import Foundation
import UIKit

/// 弹窗类型
///
/// - alert: Alert类型
/// - sheet: Sheet类型
/// - custom: 自定义类型
@objc public enum FWPopupType: Int {
    case alert
    case sheet
    case custom
}

/// 显示、隐藏回调
public typealias FWPopupBlock = (_ popupView: FWPopupView) -> Void
/// 显示、隐藏完成回调
public typealias FWPopupCompletionBlock = (_ popupView: FWPopupView, _ isCompletion: Bool) -> Void
/// 普通无参数回调
public typealias FWPopupVoidBlock = () -> Void

let FWPopupViewHideAllNotification = "FWPopupViewHideAllNotification"


@objc open class FWPopupView: UIView {
    
    /// 1、当外部没有传入该参数时，默认为UIWindow的根控制器的视图，即表示弹窗放在FWPopupWindow上，此时若FWPopupWindow.sharedInstance.touchWildToHide = true表示弹窗视图外部可点击；2、当外部传入该参数时，该视图为传入的UIView，即表示弹窗放在传入的UIView上；
    public var attachedView = FWPopupWindow.sharedInstance.attachView()
    
    public var visible: Bool {
        get {
            if self.attachedView != nil {
                return !(self.attachedView?.fwBackgroundView.isHidden)!
            }
            return false
        }
    }
    
    var popupType: FWPopupType = .alert {
        willSet {
            switch newValue {
            case .alert:
                self.showAnimation = self.alertShowAnimation()
                self.hideAnimation = self.alertHideAnimation()
                break
            case .sheet:
                self.showAnimation = self.sheetShowAnimation()
                self.hideAnimation = self.sheetHideAnimation()
                break
            case .custom:
                //                self.showAnimation = self.customShowAnimation()
                //                self.hideAnimation = self.customHideAnimation()
                break
            }
        }
    }
    
    var animationDuration: TimeInterval = 0.3 {
        willSet {
            self.attachedView?.fwAnimationDuration = newValue
        }
    }
    
    var withKeyboard = false
    
    var showCompletionBlock: FWPopupCompletionBlock?
    
    var hideCompletionBlock: FWPopupCompletionBlock?
    
    var showAnimation: FWPopupBlock?
    
    var hideAnimation: FWPopupBlock?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        FWPopupWindow.sharedInstance.backgroundColor = UIColor.clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifyHideAll(notification:)), name: NSNotification.Name(rawValue: FWPopupViewHideAllNotification), object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open func showKeyboard() {
        
    }
    
    open func hideKeyboard() {
        
    }
}

extension FWPopupView {
    
    open func show() {
        
        self.show { (self, isFinished) in
            
        }
    }
    
    func show(completionBlock:@escaping FWPopupCompletionBlock) {
        
        self.showCompletionBlock = completionBlock
        
        if self.attachedView == nil {
            self.attachedView = FWPopupWindow.sharedInstance.attachView()
        }
        self.attachedView?.showFwBackground()
        
        let showA = self.showAnimation
        showA!(self)
        
        if self.withKeyboard {
            self.showKeyboard()
        }
    }
    
    open func hide() {
        self.hide { (self, isFinished) in
            
        }
    }
    
    func hide(completionBlock:@escaping FWPopupCompletionBlock) {
        
        self.hideCompletionBlock = completionBlock
        
        if self.attachedView == nil {
            self.attachedView = FWPopupWindow.sharedInstance.attachView()
        }
        self.attachedView?.hideFwBackground()
        
        if self.withKeyboard {
            self.hideKeyboard()
        }
        
        let hideAnimation = self.hideAnimation
        hideAnimation!(self)
    }
    
    open class func hideAll() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FWPopupViewHideAllNotification), object: FWPopupView.self)
    }
    
    @objc func notifyHideAll(notification: Notification) {
        
        if self.isKind(of: notification.object as! AnyClass) {
            self.hide()
        }
    }
}

extension FWPopupView {
    
    func alertShowAnimation() -> FWPopupBlock {
        
        let popupBlock = { [weak self] (popupView: FWPopupView) in
            if self?.superview == nil {
                self?.attachedView?.fwBackgroundView.addSubview(self!)
                self?.center = (self?.attachedView?.center)!
                if (self?.withKeyboard)! {
                    self?.frame.origin.y -= 216/2
                }
                self?.layoutIfNeeded()
            }
            self?.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
            self?.alpha = 0.0
            
            UIView.animate(withDuration: (self?.animationDuration)!, delay: 0.0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                
                self?.layer.transform = CATransform3DIdentity
                self?.alpha = 1.0
                
            }, completion: { (finished) in
                
                if self?.showCompletionBlock != nil {
                    self?.showCompletionBlock!(self!, finished)
                }
                
            })
        }
        
        return popupBlock
    }
    
    func alertHideAnimation() -> FWPopupBlock {
        
        let popupBlock:FWPopupBlock = { [weak self] popupView in
            
            UIView.animate(withDuration: (self?.animationDuration)!, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                
                self?.alpha = 0.0
                
            }, completion: { (finished) in
                
                if finished {
                    self?.removeFromSuperview()
                }
                if self?.hideCompletionBlock != nil {
                    self?.hideCompletionBlock!(self!, finished)
                }
                
            })
        }
        
        return popupBlock
    }
    
    func sheetShowAnimation() -> FWPopupBlock {
        
        let popupBlock:FWPopupBlock = { [weak self] popupView in
            if self?.superview == nil {
                self?.attachedView?.fwBackgroundView.addSubview(self!)
                self?.frame.origin.y =  UIScreen.main.bounds.height - (self?.frame.height)!
                self?.layoutIfNeeded()
            }
            
            UIView.animate(withDuration: (self?.animationDuration)!, delay: 0.0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                
                self?.superview?.layoutIfNeeded()
                
            }, completion: { (finished) in
                
                if self?.showCompletionBlock != nil {
                    self?.showCompletionBlock!(self!, finished)
                }
                
            })
        }
        
        return popupBlock
    }
    
    func sheetHideAnimation() -> FWPopupBlock {

        let popupBlock:FWPopupBlock = { [weak self] popupView in
            
            UIView.animate(withDuration: (self?.animationDuration)!, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                
                self?.superview?.layoutIfNeeded()
                
            }, completion: { (finished) in
                
                if finished {
                    self?.removeFromSuperview()
                }
                if self?.hideCompletionBlock != nil {
                    self?.hideCompletionBlock!(self!, finished)
                }
                
            })
        }
        
        return popupBlock
    }

    //    func customShowAnimation() -> FWPopupBlock {
    //
    //    }
    //
    //    func customHideAnimation() -> FWPopupBlock {
    //
    //    }
    
    /// 将颜色转换为图片
    ///
    /// - Parameter color: 颜色
    /// - Returns: UIImage
    public func getImageWithColor(color: UIColor) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}


/// FWSheetView的相关属性
@objc open class FWPopupViewProperty: NSObject {
    
    // 单个点击按钮的高度
    public var buttonHeight: CGFloat        = 48.0
    // 圆角值
    public var cornerRadius: CGFloat        = 5.0
    
    // 标题字体大小
    public var titleFontSize: CGFloat       = 18.0
    // 点击按钮字体大小
    public var buttonFontSize: CGFloat      = 17.0
    
    // 弹窗的背景色
    public var vbackgroundColor: UIColor    = UIColor.white
    // 标题文字颜色
    public var titleColor: UIColor          = kPV_RGBA(r: 51, g: 51, b: 51, a: 1)
    // 边框、分割线颜色
    public var splitColor: UIColor          = kPV_RGBA(r: 231, g: 231, b: 231, a: 1)
    // 边框宽度
    public var splitWidth: CGFloat          = (1/UIScreen.main.scale)
    
    // 普通按钮颜色
    public var itemNormalColor: UIColor     = kPV_RGBA(r: 51, g: 51, b: 51, a: 1)
    // 高亮按钮颜色
    public var itemHighlightColor: UIColor  = kPV_RGBA(r: 254, g: 226, b: 4, a: 1)
    // 选中按钮颜色
    public var itemPressedColor: UIColor    = kPV_RGBA(r: 231, g: 231, b: 231, a: 1)
    
    // 上下间距
    public var topBottomMargin:CGFloat      = 10
    // 左右间距
    public var letfRigthMargin:CGFloat      = 10
    
    public override init() {
        super.init()
    }
}