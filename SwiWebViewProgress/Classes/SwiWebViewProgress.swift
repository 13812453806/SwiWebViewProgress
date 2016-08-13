//
//  SwiWebViewProgress.swift
//  SwiWebViewProgress
//
//  Created by Tuluobo on 8/13/16.
//  Copyright © 2016 Tuluobo. All rights reserved.
//

import UIKit

protocol SwiWebViewProgressDelegate: NSObjectProtocol {
	func webViewProgress(webViewProgress: SwiWebViewProgress, updateProgress progress: CGFloat)
}

let completeRPCURLPath: String = "/njkwebviewprogressproxy/complete"
let NJKInitialProgressValue: CGFloat = 0.1
let NJKInteractiveProgressValue: CGFloat = 0.5
let NJKFinalProgressValue: CGFloat = 0.9

class SwiWebViewProgress: NSObject, UIWebViewDelegate {

	var progressDelegate: SwiWebViewProgressDelegate?
	var webViewProxyDelegate: UIWebViewDelegate?
	var progressBlock: ((CGFloat) -> Void)?
	var progress: CGFloat {
		set {
			if newValue > _progress || newValue == 0 {
				_progress = newValue
				if (progressDelegate!.respondsToSelector(Selector("webViewProgress:updateProgress:"))) {
					progressDelegate!.webViewProgress(self, updateProgress: progress)
				}
				if (progressBlock != nil) {
					progressBlock!(newValue)
				}
			}

		}
		get {
			return _progress!
		}
	}
	private var _progress: CGFloat?
	// MARK: 懒加载
	lazy private var currentURL: NSURL = NSURL()
	lazy private var loadingCount: UInt = 0
	lazy private var maxLoadCount: UInt = 0
	lazy private var interactive: Bool = false

	// MARK: 私有方法
	private func startProgress() {
		if progress < NJKInitialProgressValue {
			progress = NJKInitialProgressValue
		}
	}

	private func incrementProgress() {
		var progress: CGFloat = self.progress
		let maxProgress: CGFloat = interactive ? NJKFinalProgressValue : NJKInteractiveProgressValue
		let remainPercent: CGFloat = CGFloat(loadingCount) / CGFloat(maxLoadCount)
		let increment: CGFloat = (maxProgress - progress) * remainPercent
		progress += increment
		progress = fmin(progress, maxProgress)
		self.progress = progress
	}

	private func completeProgress() {
		self.progress = 1.0
	}

	// MARK: 外部方法
	func reset() {
		maxLoadCount = 0
		loadingCount = 0
		interactive = false
		self.progress = 0.0
	}

	// MARK: UIWebViewDelegate
	func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if request.URL!.path == completeRPCURLPath {
			self.completeProgress()
			return false
		}
		var ret: Bool = true
		if webViewProxyDelegate!.respondsToSelector(#selector(UIWebViewDelegate.webView(_: shouldStartLoadWithRequest: navigationType:))) {
			ret = webViewProxyDelegate!.webView!(webView, shouldStartLoadWithRequest: request, navigationType: navigationType)
		}
		var isFragmentJump: Bool = false
		if (request.URL!.fragment != nil) {
			let nonFragmentURL: String = request.URL!.absoluteString.stringByReplacingOccurrencesOfString("#" + request.URL!.fragment!, withString: "")
			isFragmentJump = nonFragmentURL == webView.request!.URL!.absoluteString
		}
		let isTopLevelNavigation: Bool = request.mainDocumentURL!.isEqual(request.URL)
		let isHTTP: Bool = request.URL!.scheme == "http" || request.URL!.scheme == "https"
		if ret && !isFragmentJump && isHTTP && isTopLevelNavigation {
			currentURL = request.URL!
			self.reset()
		}
		return ret
	}

	func webViewDidStartLoad(webView: UIWebView) {
		if webViewProxyDelegate!.respondsToSelector(#selector(UIWebViewDelegate.webViewDidStartLoad(_:))) {
			webViewProxyDelegate!.webViewDidStartLoad!(webView)
		}
		loadingCount += 1
		maxLoadCount = max(maxLoadCount, loadingCount)
		self.startProgress()
	}

	func webViewDidFinishLoad(webView: UIWebView) {
		if webViewProxyDelegate!.respondsToSelector(#selector(UIWebViewDelegate.webViewDidFinishLoad(_:))) {
			webViewProxyDelegate!.webViewDidFinishLoad!(webView)
		}
		loadingCount -= 1
		self.incrementProgress()
		let readyState: String = webView.stringByEvaluatingJavaScriptFromString("document.readyState")!
		var interactive: Bool = readyState == "interactive"
		if interactive {
			interactive = true
			let waitForCompleteJS: String = "window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '\(webView.request!.mainDocumentURL!.scheme)://\(webView.request!.mainDocumentURL!.host)\(completeRPCURLPath)'; document.body.appendChild(iframe);  }, false);"
			webView.stringByEvaluatingJavaScriptFromString(waitForCompleteJS)
		}
		let isNotRedirect = currentURL.isEqual(webView.request!.mainDocumentURL)
		let complete: Bool = readyState == "complete"
		if complete && isNotRedirect {
			self.completeProgress()
		}
	}

	func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
		if webViewProxyDelegate!.respondsToSelector(#selector(UIWebViewDelegate.webView(_: didFailLoadWithError:))) {
			webViewProxyDelegate!.webView!(webView, didFailLoadWithError: error)
		}
		loadingCount -= 1
		self.incrementProgress()
		let readyState: String = webView.stringByEvaluatingJavaScriptFromString("document.readyState")!
		var interactive: Bool = readyState == "interactive"
		if interactive {
			interactive = true
			let waitForCompleteJS: String = "window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '\(webView.request!.mainDocumentURL!.scheme)://\(webView.request!.mainDocumentURL!.host)\(completeRPCURLPath)'; document.body.appendChild(iframe);  }, false);"
			webView.stringByEvaluatingJavaScriptFromString(waitForCompleteJS)
		}
		let isNotRedirect: Bool = currentURL.isEqual(webView.request!.mainDocumentURL)
		let complete: Bool = readyState == "complete"
		if ((complete && isNotRedirect) || error != nil) {
			self.completeProgress()
		}
	}

}

