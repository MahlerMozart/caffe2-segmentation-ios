//
//  config.swift
//  caffe2-ios
//
//  Created by Kaiwen Yuan on 2017-04-29.
//  Copyright © 2017 Kaiwen Yuan. All rights reserved.
//

// You can find full mapping in here : https://gist.github.com/maraoz/388eddec39d60c6d52d4

var caffe = try! Caffe2()


let builtInModels = ["originalNet", "tinyYolo"]
var modelPicked = builtInModels[0]

var session = URLSession()
