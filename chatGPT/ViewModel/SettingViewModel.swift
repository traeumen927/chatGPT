//
//  SettingViewModel.swift
//  chatGPT
//
//  Created by 홍정연 on 2023/06/07.
//

import Foundation
import RxSwift

class SettingViewModel {
    
    let menuSubject: BehaviorSubject<[Section]> = BehaviorSubject(value: [])
    
    func configure() {
        var sections:[Section] = [Section]()
        
        sections.append(Section(title: "Me", options: [
            .normalCell(model: OptionNormal(title: "email", systemImage: "paperplane", handler: {
                
            }, subTitle: "traeumen927@naver.com")),
            .normalCell(model: OptionNormal(title: "Blog", systemImage: "pencil.and.outline", handler: {
                
            }, subTitle: "https://blog.naver.com/traeumen927")),
            .normalCell(model: OptionNormal(title: "GitHub", systemImage: "server.rack", handler: {
                
            }, subTitle: "https://github.com/traeumen927/chatGPT"))
        ]))
        
        sections.append(Section(title: "CHAT", options: [
            .normalCell(model: OptionNormal(title: "Model", systemImage: "globe.americas", handler: {
                
            }, subTitle: Setting.shared.model)),
            .switchCell(model: OptionSwitch(title: "Haptic Feedback", systemImage: "water.waves", handler: { isOn in 
                Setting.shared.haptic = isOn
            }, isOn: Setting.shared.haptic)),
            .switchCell(model: OptionSwitch(title: "Chat Stream", systemImage: "questionmark.bubble", handler: { isOn in
                Setting.shared.stream = isOn
            }, isOn: Setting.shared.stream))
        ]))
        
        self.menuSubject.onNext(sections)
    }
}
