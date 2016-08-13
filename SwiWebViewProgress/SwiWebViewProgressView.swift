//
//  SwiWebViewProgressView.swift
//  SwiWebViewProgress
//
//  Created by Tuluobo on 8/13/16.
//  Copyright © 2016 Tuluobo. All rights reserved.
//

import UIKit

class SwiWebViewProgressView: UIView {

	var progress: CFloat?
	var progressColor: UIColor? {
		set {
			_progressColor = newValue
			progressBarView.backgroundColor = newValue
		}
		get {
			return _progressColor
		}
	}
	var progressBarView: UIView!
	var barAnimationDuration: NSTimeInterval = 0.1
	var fadeAnimationDuration: NSTimeInterval = 0.27
	var fadeOutDelay: NSTimeInterval = 0.1
	private var _progressColor: UIColor?

	override init(frame: CGRect) {
		super.init(frame: frame)
		if nil == self.progressColor {
			self.progressColor = UIColor.redColor()
		}
		self.userInteractionEnabled = false
		self.autoresizingMask = .FlexibleWidth
		progressBarView = UIView(frame: self.bounds)
		progressBarView.autoresizingMask = UIViewAutoresizing(rawValue: UIViewAutoresizing.FlexibleWidth.rawValue | UIViewAutoresizing.FlexibleHeight.rawValue)
		progressBarView.backgroundColor = _progressColor
		self.addSubview(progressBarView)
		barAnimationDuration = 0.27
		fadeAnimationDuration = 0.27
		fadeOutDelay = 0.1
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private func setProgress(progress: CFloat) {
		self.setProgress(progress, animated: false)
	}

	func setProgress(progress: CFloat, animated: Bool) {
		let isGrowing: Bool = progress > 0.0
		UIView.animateWithDuration((isGrowing && animated) ? barAnimationDuration : 0.0, delay: 0, options: .CurveEaseInOut, animations: {
			var frame: CGRect = self.progressBarView.frame
			frame.size.width = CGFloat(progress) * self.bounds.size.width
			self.progressBarView.frame = frame
			}, completion: nil)
		let duration = animated ? fadeAnimationDuration : 0.0
		if progress >= 1.0 {
			UIView.animateWithDuration(duration, delay: fadeOutDelay, options: .CurveEaseInOut, animations: {
				self.progressBarView.alpha = 0.0
				}, completion: { (completed: Bool) in
				var frame: CGRect = self.progressBarView.frame
				frame.size.width = 0
				self.progressBarView.frame = frame

			})
		} else {
			UIView.animateWithDuration(duration, delay: 0.0, options: .CurveEaseInOut, animations: {
				self.progressBarView.alpha = 1.0
				}, completion: nil)

		}
	}

}

