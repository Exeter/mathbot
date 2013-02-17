//
//  main.m
//  Zfeng
//
//  Created by Weihang Fan on 2/17/13.
//  Copyright (c) 2013 Weihang Fan. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MacRuby/MacRuby.h>

int main(int argc, char *argv[])
{
    return macruby_main("rb_main.rb", argc, argv);
}
