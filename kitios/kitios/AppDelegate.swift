//
//  AppDelegate.swift
//  kitios
//
//  Created by Graeme Costin on 4/5/20.
// The author disclaims copyright to this source code.  In place of
// a legal notice, here is a blessing:
//
//    May you do good and not evil.
//    May you find forgiveness for yourself and forgive others.
//    May you share freely, never taking more than you give.

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	// A pointer to the one and only KITDAO instance is kept in the AppDelegate
	// so that all parts of the app can use it
	var dao: KITDAO?
		
	public var bibInst: Bible?			// During the launch of KIT an instance of the class Bible will be created
	public var bookInst: Book?			// Once launching is complete there will be an instance of the current Book
	public var chapInst: Chapter?		// Once launching is complete there will be an instance of the current Chapter
	public var VTVCtrl: VersesTableViewController?	// Once a Chapter of a Book is opened there will be a VersesTableViewController

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		dao = KITDAO()	// create an instance of the Data Access Object and keep reference to it

		return true
	}
	
	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
		print("AppDelegate KIT will resign from Active")
		// Save the current VerseItem if necessary
		if VTVCtrl != nil {
			VTVCtrl!.saveCurrentItemText()
		}
	}
	
	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
		print("AppDelegate KIT has entered background")
		// KIT does not do background execution so nothing to do here.
	}
	
	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
		
		print("AppDelegate KIT about to enter foreground")
		// KIT does not enter background execution so nothing to do here.
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		
		print("AppDelegate KIT became active")
		// KIT should refresh its user interface when returning to foreground??
//		bibInst!.refreshUIAfterReturnToForeground()
		
	}
	
	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		
		print("AppDelegate KIT will now terminate")
		// KIT needs to delete its instance of the class Bible and all the instances that are owned by it,
		// including the instance of KITDAO (which closes the kdb.sqlite database)
		bibInst = nil
	}


}
