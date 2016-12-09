//
//  UIScrollView+RxTests.swift
//  Tests
//
//  Created by Suyeol Jeon on 6/8/16.
//  Copyright © 2016 Krunoslav Zaher. All rights reserved.
//

#if os(iOS)

import Foundation

import RxSwift
import RxCocoa
import UIKit
import XCTest
import RxTest

class UIScrollViewTests : RxTest {}

extension UIScrollViewTests {

    func testScrollEnabled_False() {
        let scrollView = UIScrollView()
        scrollView.isScrollEnabled = true

        Observable.just(false).bindTo(scrollView.rx.isScrollEnabled).dispose()
        XCTAssertTrue(scrollView.isScrollEnabled == false)
    }

    func testScrollEnabled_True() {
        let scrollView = UIScrollView(frame: CGRect.zero)
        scrollView.isScrollEnabled = false

        Observable.just(true).bindTo(scrollView.rx.isScrollEnabled).dispose()
        XCTAssertTrue(scrollView.isScrollEnabled == true)
    }

    func testScrollView_DelegateEventCompletesOnDealloc() {
        let createView: () -> UIScrollView = { UIScrollView(frame: CGRect(x: 0, y: 0, width: 1, height: 1)) }
        ensurePropertyDeallocated(createView, CGPoint(x: 1, y: 1)) { (view: UIScrollView) in view.rx.contentOffset }
    }

    func testScrollViewDidScroll() {
        var completed = false
        
        autoreleasepool {
            let scrollView = UIScrollView()
            var didScroll = false

            _ = scrollView.rx.didScroll.subscribe(onNext: {
                didScroll = true
            }, onCompleted: {
                completed = true
            })

            XCTAssertFalse(didScroll)

            scrollView.delegate!.scrollViewDidScroll!(scrollView)

            XCTAssertTrue(didScroll)
        }

        XCTAssertTrue(completed)
    }
	
	
	func testScrollViewDidEndDecelerating() {
		var completed = false
		
		autoreleasepool {
			let scrollView = UIScrollView()
			var didEndDecelerating = false
			
			_ = scrollView.rx.didEndDecelerating.subscribe(onNext: {
				didEndDecelerating = true
			}, onCompleted: {
				completed = true
			})
			
			XCTAssertFalse(didEndDecelerating)
			
			scrollView.delegate!.scrollViewDidEndDecelerating!(scrollView)
			
			XCTAssertTrue(didEndDecelerating)
		}
		
		XCTAssertTrue(completed)
	}
	
	func testScrollViewDidEndDragging() {
		let scheduler = TestScheduler(initialClock: 0)
		let results = scheduler.createObserver(Bool.self)
		
		autoreleasepool {
			let scrollView = UIScrollView()
			
			let o = scheduler.createHotObservable([
				next(250, false),
				next(300, true),
				])
			
			let subscription: Disposable! = scrollView.rx.didEndDragging.subscribe(results)
			
			_ = scheduler.start {
				o.do(onNext: {
					scrollView.delegate!.scrollViewDidEndDragging!(scrollView, willDecelerate: $0)
				}, onDispose: {
					subscription.dispose()
				})
			}
		}
		XCTAssertEqual(results.events, [
			next(250, false),
			next(300, true)
			])
	}

    func testScrollViewContentOffset() {
        var completed = false

        autoreleasepool {
            let scrollView = UIScrollView()
            scrollView.contentOffset = .zero

            var contentOffset = CGPoint(x: -1, y: -1)

            _ = scrollView.rx.contentOffset.subscribe(onNext: { value in
                contentOffset = value
            }, onCompleted: {
                completed = true
            })

            XCTAssertEqual(contentOffset, .zero)

            scrollView.contentOffset = CGPoint(x: 2, y: 2)
            scrollView.delegate!.scrollViewDidScroll!(scrollView)

            XCTAssertEqual(contentOffset, CGPoint(x: 2, y: 2))
        }

        XCTAssertTrue(completed)
    }

    func testScrollViewDidZoom() {
        let scrollView = UIScrollView()
        var didZoom = false

        let subscription = scrollView.rx.didZoom.subscribe(onNext: {
            didZoom = true
        })

        XCTAssertFalse(didZoom)

        scrollView.delegate!.scrollViewDidZoom!(scrollView)

        XCTAssertTrue(didZoom)
        subscription.dispose()
    }

    func testScrollToTop() {
        let scrollView = UIScrollView()
        var didScrollToTop = false

        let subscription = scrollView.rx.didScrollToTop.subscribe(onNext: {
            didScrollToTop = true
        })

        XCTAssertFalse(didScrollToTop)

        scrollView.delegate!.scrollViewDidScrollToTop!(scrollView)

        XCTAssertTrue(didScrollToTop)
        subscription.dispose()
    }
}

@objc class MockScrollViewDelegate
    : NSObject
    , UIScrollViewDelegate {}

extension UIScrollViewTests {
    func testSetDelegateUsesWeakReference() {
        let scrollView = UIScrollView()

        var delegateDeallocated = false

        autoreleasepool {
            let delegate = MockScrollViewDelegate()
            _ = scrollView.rx.setDelegate(delegate)

            _ = delegate.rx.deallocated.subscribe(onNext: { _ in
                delegateDeallocated = true
            })

            XCTAssert(delegateDeallocated == false)
        }
        XCTAssert(delegateDeallocated == true)
    }
}

#endif
