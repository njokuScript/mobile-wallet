//
//  CreateWallet.m
//  theQRL
//
//  Created by abilican on 17.05.18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "CreateWallet.h"
#import <React/RCTLog.h>
#import <Foundation/Foundation.h>
#import "KyberIos.h"
#import "testingEphemeral.h"
#import <GRPCClient/GRPCCall+ChannelArg.h>
#import <GRPCClient/GRPCCall+Tests.h>
#import <theQRL/Qrl.pbrpc.h>
#import <kyber.h>
#import "dilithium.h"
#import "xmss.h"
#import "xmssBase.h"
#import "xmssBasic.h"
#import "xmssFast.h"
#import "misc.h"
#include <xmssBasic.h>
#include <iostream>
#import "WalletHelperFunctions.h"

@implementation CreateWallet
RCT_EXPORT_MODULE();

// Create wallet function that returns the wallet address as a callback
//RCT_EXPORT_METHOD(createWallet:(NSString*)hashFunction (RCTResponseSenderBlock)callback )
RCT_EXPORT_METHOD(createWallet:(NSNumber* _Nonnull)treeHeight withIndex:(NSString*)walletindex withName:(NSString*)walletname withPin:(NSString*)walletpin hashFunction:(NSNumber* _Nonnull)hashFunction callback:(RCTResponseSenderBlock)callback)
{
  // Remove all previous data from the keychain
//  NSDictionary *spec = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword};
//  SecItemDelete((__bridge CFDictionaryRef)spec);
  
  // empty array of unsigned char
  unsigned char seed_array[48];
  // filling the array with randombytes
  randombytes(seed_array, 48);
  // converting array to vector
  std::vector<unsigned char> seed(seed_array, seed_array + sizeof seed_array / sizeof seed_array[0]);

  // create wallet according to the hash function
  int treeHeightInt = [treeHeight intValue];
  int hashFunctionIndex = [hashFunction intValue];
  
  eHashFunction walletHashFunction;
  
  switch(hashFunctionIndex) {
    case 1: {
      walletHashFunction = eHashFunction::SHAKE_128;
      break; //optional
    }
    case 2: {
      walletHashFunction = eHashFunction::SHAKE_256;
      break; //optional
    }
    case 3: {
      walletHashFunction = eHashFunction::SHA2_256;
      break;
    }
    default: {
      walletHashFunction = eHashFunction::SHAKE_128;
      break;
    }
  }
  
  // creating new wallet
  XmssFast xmss = XmssFast(seed, treeHeightInt, walletHashFunction, eAddrFormatType::SHA256_2X);
  std::string hexSeed = bin2hstr(xmss.getExtendedSeed());
  
  // saving the hexSeed to the keychain
  NSString *hexSeedNSString = [NSString stringWithCString:hexSeed.c_str() encoding:[NSString defaultCStringEncoding]];
  OSStatus sts = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"hexseed", walletindex] withValue:hexSeedNSString];
  
  // remove hexseed from keychain (for debugging only)
//  OSStatus sts = SecItemDelete((__bridge CFDictionaryRef)keychainItem);
  
  // send callback to RN
  if( (int)sts == 0 ){
    // saving wallet address to the keychain
    NSString *wallet_address = [NSString stringWithCString:bin2hstr(xmss.getAddress()).c_str() encoding:[NSString defaultCStringEncoding]];
    OSStatus sts2 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"address", walletindex] withValue:wallet_address];
    if( (int)sts2 == 0 ){
      // wallet successfuly created ans hexseed saved to the keychain
      NSString *xmss_pk = [NSString stringWithCString:bin2hstr(xmss.getPK()).c_str() encoding:[NSString defaultCStringEncoding]];
      //save wallet address to the keychain
      OSStatus sts3 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"xmsspk", walletindex] withValue:xmss_pk];
      if( (int)sts3 == 0 ){
        NSNumber *tree_height_nb = [NSNumber numberWithInt:xmss.getHeight()];
        NSString *tree_height = [tree_height_nb stringValue];
        //save wallet address to the keychain
        OSStatus sts4 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"treeheight", walletindex] withValue:tree_height];
        if( (int)sts4 == 0 ){
//          callback(@[[NSNull null], @"success",  wallet_address ]);
          OSStatus sts5 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"pin", walletindex] withValue:walletpin];
          if( (int)sts5 == 0 ){
            
            callback(@[[NSNull null], @"success",  wallet_address ]);
//            OSStatus sts6 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"name", walletindex] withValue:walletname];
//            if( (int)sts6 == 0 ){
//                callback(@[[NSNull null], @"success",  wallet_address ]);
//            }
//            else {
//              NSLog(@"ERROR saving wallet name to keychain: %d",(int)sts6);
//              callback(@[[NSNull null], @"error" ]);
//            }
          }
          else {
            NSLog(@"ERROR saving pin to keychain: %d",(int)sts5);
            callback(@[[NSNull null], @"error" ]);
          }

        }
        else {
          NSLog(@"ERROR saving treeheight to keychain: %d",(int)sts4);
          callback(@[[NSNull null], @"error" ]);
        }
      }
      else {
        NSLog(@"ERROR saving xmsspk to keychain: %d",(int)sts3);
        callback(@[[NSNull null], @"error" ]);
      }
    }
    else {
      NSLog(@"ERROR saving address to keychain: %d",(int)sts2);
      callback(@[[NSNull null], @"error" ]);
    }
  }
  else{
    NSLog(@"ERROR saving hexseed to keychain: %d",(int)sts);
    callback(@[[NSNull null], @"error" ]);
  }
}




RCT_EXPORT_METHOD(openWalletWithMnemonic:(NSString* )mnemonicNSString withIndex:(NSString*)walletindex withName:(NSString*)walletname withPin:(NSString*)walletpin callback:(RCTResponseSenderBlock)callback){
  // check whether user is using hexseed or mnemonic
  // mnemonic
  NSLog(@"IT IS A MNEMONIC");
  std::string mnemonic = std::string([mnemonicNSString UTF8String]);
  std::vector<unsigned char> mnemonicUchar = mnemonic2bin(mnemonic);
  std::string hexseedStdStrind = bin2hstr(mnemonicUchar);
  
  NSString *hexseed = [NSString stringWithCString:hexseedStdStrind.c_str() encoding:[NSString defaultCStringEncoding]];
  
  // convert hexseed NSString to a vector of uint8_t
  std::vector<uint8_t> hexSeed= {};
  
  // Opening XMSS object with hexseed
  for (int i=0; i < [hexseed length]; i+=2) {
    NSString* subs = [hexseed substringWithRange:NSMakeRange(i, 2)];
    // converting hex to corresponding decimal
    unsigned result = 0;
    NSScanner* scanner = [NSScanner scannerWithString:subs];
    [scanner scanHexInt:&result];
    // adding to hex
    hexSeed.push_back(result);
  }
  
  // try to open the wallet
  try{
    QRLDescriptor desc = QRLDescriptor::fromExtendedSeed(hexSeed);
    //    [NSString stringWithFormat:@"%@%@%@", three, two, one];
    //    OSStatus sts = [WalletHelperFunctions saveToKeychain:@"hexseed" withValue:hexseed];
    OSStatus sts = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"hexseed", walletindex] withValue:hexseed];
    
    // send callback to RN
    if( (int)sts == 0 ){
      // hexseed successfuly saved to the keychain
      hexSeed.erase(hexSeed.begin(), hexSeed.begin() + 3);
      XmssFast xmss = XmssFast( hexSeed, desc.getHeight(), desc.getHashFunction(), eAddrFormatType::SHA256_2X);
      NSString *wallet_address = [NSString stringWithCString:bin2hstr(xmss.getAddress()).c_str() encoding:[NSString defaultCStringEncoding]];
      //save wallet address to the keychain
      OSStatus sts2 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"address", walletindex] withValue:wallet_address];
      if( (int)sts2 == 0 ){
        NSString *xmss_pk = [NSString stringWithCString:bin2hstr(xmss.getPK()).c_str() encoding:[NSString defaultCStringEncoding]];
        //save wallet address to the keychain
        OSStatus sts3 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"xmsspk", walletindex] withValue:xmss_pk];
        if( (int)sts3 == 0 ){
          NSNumber *tree_height_nb = [NSNumber numberWithInt:xmss.getHeight()];
          NSString *tree_height = [tree_height_nb stringValue];
          //save wallet address to the keychain
          OSStatus sts4 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"treeheight", walletindex] withValue:tree_height];
          if( (int)sts4 == 0 ){
            // callback(@[[NSNull null], @"success", wallet_address ]);
            OSStatus sts5 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"pin", walletindex] withValue:walletpin];
            if( (int)sts5 == 0 ){
              
              callback(@[[NSNull null], @"success",  wallet_address ]);
//              OSStatus sts6 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"name", walletindex] withValue:walletname];
//              if( (int)sts6 == 0 ){
//                callback(@[[NSNull null], @"success",  wallet_address ]);
//              }
//              else {
//                NSLog(@"ERROR saving wallet name to keychain: %d",(int)sts6);
//                callback(@[[NSNull null], @"error" ]);
//              }
              
            }
            else {
              NSLog(@"ERROR saving pin to keychain: %d",(int)sts5);
              callback(@[[NSNull null], @"error" ]);
            }
            
          }
          else {
            NSLog(@"ERROR saving treeheight to keychain: %d",(int)sts4);
            callback(@[[NSNull null], @"error" ]);
          }
        }
        else {
          NSLog(@"ERROR saving xmsspk to keychain: %d",(int)sts3);
          callback(@[[NSNull null], @"error" ]);
        }
      }
      else {
        NSLog(@"ERROR saving address to keychain: %d",(int)sts2);
        callback(@[[NSNull null], @"error" ]);
      }
    }
    else {
      NSLog(@"ERROR saving hexseed to keychain: %d",(int)sts);
      callback(@[[NSNull null], @"error" ]);
    }
  }
  // error in hexseed
  catch (...){
    callback(@[[NSNull null], @"error" ]);
  }
  
}




// save the user's entered hexseed to keychain
RCT_EXPORT_METHOD(openWalletWithHexseed:(NSString* )hexseed withIndex:(NSString*)walletindex withName:(NSString*)walletname withPin:(NSString*)walletpin callback:(RCTResponseSenderBlock)callback){
  
  // Remove all previous data from the keychain
//  NSDictionary *spec = @{(__bridge id)kSecClass:(__bridge id)kSecClassGenericPassword};
//  SecItemDelete((__bridge CFDictionaryRef)spec);
    
  // convert hexseed NSString to a vector of uint8_t
  std::vector<uint8_t> hexSeed= {};
  
  // Opening XMSS object with hexseed
  for (int i=0; i < [hexseed length]; i+=2) {
    NSString* subs = [hexseed substringWithRange:NSMakeRange(i, 2)];
    // converting hex to corresponding decimal
    unsigned result = 0;
    NSScanner* scanner = [NSScanner scannerWithString:subs];
    [scanner scanHexInt:&result];
    // adding to hex
    hexSeed.push_back(result);
  }
  
  
  // try to open the wallet
  try{
    QRLDescriptor desc = QRLDescriptor::fromExtendedSeed(hexSeed);
//    [NSString stringWithFormat:@"%@%@%@", three, two, one];
//    OSStatus sts = [WalletHelperFunctions saveToKeychain:@"hexseed" withValue:hexseed];
    OSStatus sts = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"hexseed", walletindex] withValue:hexseed];
    
    // send callback to RN
    if( (int)sts == 0 ){
      // hexseed successfuly saved to the keychain
      hexSeed.erase(hexSeed.begin(), hexSeed.begin() + 3);
      XmssFast xmss = XmssFast( hexSeed, desc.getHeight(), desc.getHashFunction(), eAddrFormatType::SHA256_2X);
      NSString *wallet_address = [NSString stringWithCString:bin2hstr(xmss.getAddress()).c_str() encoding:[NSString defaultCStringEncoding]];
      //save wallet address to the keychain
      OSStatus sts2 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"address", walletindex] withValue:wallet_address];
      if( (int)sts2 == 0 ){
        NSString *xmss_pk = [NSString stringWithCString:bin2hstr(xmss.getPK()).c_str() encoding:[NSString defaultCStringEncoding]];
        //save wallet address to the keychain
        OSStatus sts3 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"xmsspk", walletindex] withValue:xmss_pk];
        if( (int)sts3 == 0 ){
          NSNumber *tree_height_nb = [NSNumber numberWithInt:xmss.getHeight()];
          NSString *tree_height = [tree_height_nb stringValue];
          //save wallet address to the keychain
          OSStatus sts4 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"treeheight", walletindex] withValue:tree_height];
          if( (int)sts4 == 0 ){
//            callback(@[[NSNull null], @"success", wallet_address ]);
            
            OSStatus sts5 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"pin", walletindex] withValue:walletpin];
            if( (int)sts5 == 0 ){

              callback(@[[NSNull null], @"success",  wallet_address ]);

//              OSStatus sts6 = [WalletHelperFunctions saveToKeychain:[NSString stringWithFormat:@"%@%@", @"name", walletindex] withValue:walletname];
//              if( (int)sts6 == 0 ){
//                callback(@[[NSNull null], @"success",  wallet_address ]);
//              }
//              else {
//                NSLog(@"ERROR saving wallet name to keychain: %d",(int)sts6);
//                callback(@[[NSNull null], @"error" ]);
//              }
              
            }
            else {
              NSLog(@"ERROR saving pin to keychain: %d",(int)sts5);
              callback(@[[NSNull null], @"error" ]);
            }
            
          }
          else {
            NSLog(@"ERROR saving treeheight to keychain: %d",(int)sts4);
            callback(@[[NSNull null], @"error" ]);
          }
        }
        else {
          NSLog(@"ERROR saving xmsspk to keychain: %d",(int)sts3);
          callback(@[[NSNull null], @"error" ]);
        }
      }
      else {
        NSLog(@"ERROR saving address to keychain: %d",(int)sts2);
        callback(@[[NSNull null], @"error" ]);
      }
    }
    else {
      NSLog(@"ERROR saving hexseed to keychain: %d",(int)sts);
      callback(@[[NSNull null], @"error" ]);
    }
  }
  // error in hexseed
  catch (...){
    callback(@[[NSNull null], @"error" ]);
  }
  
}

// removing a wallet items from the keychain
RCT_EXPORT_METHOD(closeWallet:(NSString* )walletindex  callback:(RCTResponseSenderBlock)callback){
  
  OSStatus sts1 = [WalletHelperFunctions removeFromKeychain:[NSString stringWithFormat:@"%@%@", @"pin", walletindex]];
  if( (int)sts1 == 0 ){
  
    OSStatus sts2 = [WalletHelperFunctions removeFromKeychain:[NSString stringWithFormat:@"%@%@", @"hexseed", walletindex]];
    if( (int)sts2 == 0 ){
      
      OSStatus sts3 = [WalletHelperFunctions removeFromKeychain:[NSString stringWithFormat:@"%@%@", @"address", walletindex]];
      if( (int)sts3 == 0 ){
        
        OSStatus sts4 = [WalletHelperFunctions removeFromKeychain:[NSString stringWithFormat:@"%@%@", @"xmsspk", walletindex]];
        if( (int)sts4 == 0 ){
          
          OSStatus sts5 = [WalletHelperFunctions removeFromKeychain:[NSString stringWithFormat:@"%@%@", @"treeheight", walletindex]];
          if( (int)sts5 == 0 ){
          
            callback(@[[NSNull null], @"success" ]);
//            OSStatus sts6 = [WalletHelperFunctions removeFromKeychain:[NSString stringWithFormat:@"%@%@", @"name", walletindex]];
//            if( (int)sts6 == 0 ){
//              NSLog(@"Wallet removed from Keychain");
//              callback(@[[NSNull null], @"success" ]);
//            }
//            else {
//              NSLog(@"ERROR removing name from keychain: %d",(int)sts5);
//              callback(@[[NSNull null], @"error" ]);
//            }

          }
          else {
            NSLog(@"ERROR removing treeheight from keychain: %d",(int)sts5);
            callback(@[[NSNull null], @"error" ]);
          }
          
        }
        else {
          NSLog(@"ERROR removing xmsspk from keychain: %d",(int)sts4);
          callback(@[[NSNull null], @"error" ]);
        }
        
      }
      else {
        NSLog(@"ERROR removing address from keychain: %d",(int)sts3);
        callback(@[[NSNull null], @"error" ]);
      }
      
    }
    else {
      NSLog(@"ERROR removing hexseed from keychain: %d",(int)sts2);
      callback(@[[NSNull null], @"error" ]);
    }
    
  }
  else {
    NSLog(@"ERROR removing pin from keychain: %d",(int)sts1);
    callback(@[[NSNull null], @"error" ]);
  }

}


// check if user provided hexseed is correct for a given wallet and return wallet if true
RCT_EXPORT_METHOD(checkHexseedIdentical:(NSString* )userHexseed withIndex:(NSString*)walletindex callback:(RCTResponseSenderBlock)callback){
  NSString* hexseed = [WalletHelperFunctions getFromKeychain:[NSString stringWithFormat:@"%@%@", @"hexseed", walletindex]];
  // if provided hexseed is correct then open the wallet
  if ([hexseed isEqualToString:userHexseed]){
    callback(@[[NSNull null], @"success" ]);
  }
  // if not return error
  else {
    callback(@[[NSNull null], @"error" ]);
  }
}

// Return wallet PIN to check
RCT_EXPORT_METHOD(getWalletPin:(NSString*)walletindex callback:(RCTResponseSenderBlock)callback ){
  NSString* walletpin = [WalletHelperFunctions getFromKeychain:[NSString stringWithFormat:@"%@%@", @"pin", walletindex]];
  callback(@[[NSNull null], walletpin ]);
}


@end


