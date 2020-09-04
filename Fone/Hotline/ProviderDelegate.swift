/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AVFoundation
import CallKit
import UIKit

class ProviderDelegate: NSObject {
  private let callManager: CallManager
  private let provider: CXProvider
  
  init(callManager: CallManager) {
    self.callManager = callManager
    provider = CXProvider(configuration: ProviderDelegate.providerConfiguration)
    
    super.init()

    provider.setDelegate(self, queue: nil)
  }
  
  static var providerConfiguration: CXProviderConfiguration = {
    let providerConfiguration = CXProviderConfiguration(localizedName: "Fone")
    providerConfiguration.ringtoneSound = "iphone-original.caf"
    providerConfiguration.supportsVideo = true
    providerConfiguration.maximumCallsPerCallGroup = 1
    providerConfiguration.supportedHandleTypes = [.phoneNumber]
    
    return providerConfiguration
  }()
  
  func reportIncomingCall(
    uuid: UUID,
    handle: String,
    hasVideo: Bool = false,
    completion: ((Error?) -> Void)?
  ) {
    let update = CXCallUpdate()
    update.remoteHandle = CXHandle(type: .phoneNumber, value: handle)
    update.hasVideo = hasVideo
    
    provider.reportNewIncomingCall(with: uuid, update: update) { error in
      if error == nil {
        let call = Call(uuid: uuid, handle: handle)
        self.callManager.add(call: call)
      }
      
      completion?(error)
    }
  }
}

// MARK: - CXProviderDelegate
extension ProviderDelegate: CXProviderDelegate {
  func providerDidReset(_ provider: CXProvider) {
    stopAudio()
    
    for call in callManager.calls {
      call.end()
    }
    
    callManager.removeAllCalls()
  }
  
  func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
      action.fail()
      return
    }
    
    configureAudioSession()
    
    call.answer()

    if NotificationHandler.shared.callType == "AD"{
        let uiStoryboard = UIStoryboard(name: "Home", bundle: nil)
        let desiredVC = uiStoryboard.instantiateViewController(withIdentifier: "VideoCallVC")
        topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)
    }else if NotificationHandler.shared.callType == "VD"{
        let tabBarController = UIStoryboard().loadTabBarController()
        let selectedIndexe = tabBarController.selectedIndex
        let desiredVC = UIStoryboard().loadVideoCallVC()
        desiredVC.isVideo = true
        
        if selectedIndexe == 0 {
            topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)
        }
        else if selectedIndexe == 1 {
            topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)
        }
        else if selectedIndexe == 2 {
            topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)
        }
        else
        {
            topViewController()?.navigationController?.present(desiredVC, animated: true, completion: nil)
        }
    }
    
    action.fulfill()
  }
  
  func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
    startAudio()
  }
  
  func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
      action.fail()
      return
    }
    if NotificationHandler.shared.callStatus ?? false
    {
        topViewController()?.sendMissedCallNotificationAPI()
    }
    stopAudio()
    
    call.end()

    action.fulfill()

    callManager.remove(call: call)
  }
  
  func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
    guard let call = callManager.callWithUUID(uuid: action.callUUID) else {
      action.fail()
      return
    }
    
    call.state = action.isOnHold ? .held : .active
    
    if call.state == .held {
      stopAudio()
    } else {
      startAudio()
    }
    
    action.fulfill()
  }
  
  func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
    let call = Call(uuid: action.callUUID, outgoing: true,
                    handle: action.handle.value)

    configureAudioSession()

    call.connectedStateChanged = { [weak self, weak call] in
      guard
        let self = self,
        let call = call
        else {
          return
      }
      
      if call.connectedState == .pending {
        self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: nil)
      } else if call.connectedState == .complete {
        self.provider.reportOutgoingCall(with: call.uuid, connectedAt: nil)
      }
    }

    call.start { [weak self, weak call] success in
      guard
        let self = self,
        let call = call
        else {
          return
      }
      
      if success {
        action.fulfill()
        self.callManager.add(call: call)
      } else {
        action.fail()
      }
    }
  }
}
