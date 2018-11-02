import React from 'react';
import {Text, View, Button, Image, ImageBackground, StyleSheet, TouchableHighlight, TouchableOpacity, Platform, ActivityIndicator} from 'react-native';

import {NativeModules} from 'react-native';
var IosWallet = NativeModules.refreshWallet;
var AndroidWallet = NativeModules.AndroidWallet;

export default class txDetailsView extends React.Component {

    static navigationOptions = {
         drawerLabel: () => null
    };

    componentDidMount() {
        // Ios
        this.setState({isLoading:true})
        if (Platform.OS === 'ios'){
            IosWallet.getTxDetails(this.props.navigation.state.params.txhash, (error, result)=> {
                // convert result to JSON
                var results = JSON.parse(result);
                this.setState({isLoading:false, blocknumber: results.blocknumber, nonce: results.nonce});
            });
        }
        // Android
        else {
            AndroidWallet.refreshWallet( (err) => {console.log(err);}, (walletAddress, otsIndex, balance, keys)=> {
                this.setState({isLoading:false, updatedDate: new Date(), balance: balance, otsIndex: otsIndex, dataSource: ds.cloneWithRows(JSON.parse(keys) )})
            });
        }
    }

    state={isLoading:true}

  // render view
  render() {
      if (this.state.isLoading){
          return (
              <ImageBackground source={require('../resources/images/sendreceive_bg_half.jpg')} style={styles.backgroundImage}>
                <View style={{flex:1}}>

                    <View style={{alignItems:'flex-start', justifyContent:'flex-start', paddingTop:40, paddingLeft:30}}>
                        <TouchableHighlight onPress={()=> this.props.navigation.navigate("TransactionsHistory")} underlayColor='white'>
                          <Image source={require('../resources/images/whiteArrowLeft.png')} resizeMode={Image.resizeMode.contain} style={{height:25, width:25}} />
                        </TouchableHighlight>
                    </View>
                    <View style={{ height:130, width:330, borderRadius:10, alignSelf:'center', marginTop: 30}}>
                        <ImageBackground source={require('../resources/images/backup_bg.png')} imageStyle={{resizeMode: 'contain'}} style={styles.backgroundImage2}>
                            <View style={{flex:1, alignSelf:'center', width:330, justifyContent:'center', alignItems:'center'}}>
                                <Text style={{color:'white', fontSize:20}}>TRANSACTION DETAILS</Text>
                            </View>
                        </ImageBackground>
                    </View>
                    <View style={{flex:1, paddingTop: 50, paddingBottom:100, width:330, alignSelf: 'center',  borderRadius:10}}>
                        <View style={{height:50, backgroundColor:'white'}}>
                            <View style={{flex:1, justifyContent:'center', alignItems:'center', backgroundColor:'#fafafa'}}>
                                <Text style={{justifyContent:'center'}}>{this.props.navigation.state.params.txhash}</Text>
                            </View>
                        </View>
                        <View style={{width:'100%',height:1, backgroundColor:'red', alignSelf:'flex-end'}}></View>
                        <View style={{flex:2, backgroundColor:'white', width:330, padding:30, alignItems:'center'}}>
                            <View>
                                <Text>{this.props.navigation.state.params.txhash}</Text>
                                <Text>Loading...</Text>
                            </View>
                        </View>
                    </View>
                </View>
            </ImageBackground>
          );

      }
      else {
          return (
              <ImageBackground source={require('../resources/images/sendreceive_bg_half.jpg')} style={styles.backgroundImage}>
                <View style={{flex:1}}>

                    <View style={{alignItems:'flex-start', justifyContent:'flex-start', paddingTop:40, paddingLeft:30}}>
                        <TouchableHighlight onPress={()=> this.props.navigation.navigate("TransactionsHistory")} underlayColor='white'>

                          <Image source={require('../resources/images/whiteArrowLeft.png')} resizeMode={Image.resizeMode.contain} style={{height:25, width:25}} />
                        </TouchableHighlight>
                    </View>
                    <View style={{ height:130, width:330, borderRadius:10, alignSelf:'center', marginTop: 30}}>
                        <ImageBackground source={require('../resources/images/backup_bg.png')} imageStyle={{resizeMode: 'contain'}} style={styles.backgroundImage2}>
                            <View style={{flex:1, alignSelf:'center', width:330, justifyContent:'center', alignItems:'center'}}>
                                <Text style={{color:'white', fontSize:20}}>TRANSACTION DETAILS</Text>
                            </View>
                        </ImageBackground>
                    </View>
                    <View style={{flex:1, paddingTop: 50, paddingBottom:100, width:330, alignSelf: 'center',  borderRadius:10}}>
                        <View style={{height:50, backgroundColor:'white'}}>
                            <View style={{flex:1, justifyContent:'center', alignItems:'center', backgroundColor:'#fafafa'}}>
                                <Text style={{justifyContent:'center'}}>Transfer</Text>
                            </View>
                        </View>
                        <View style={{width:'100%',height:1, backgroundColor:'red', alignSelf:'flex-end'}}></View>
                        <View style={{flex:2, backgroundColor:'white', width:330, padding:30, alignItems:'center'}}>
                            <View>
                                <Text>Transaction: {this.props.navigation.state.params.txhash}</Text>
                                <Text>Block: {this.state.blocknumber}</Text>
                                <Text>Nonce: {this.state.nonce}</Text>
                            </View>
                        </View>
                    </View>
                </View>
            </ImageBackground>
          );

      }
  }
}


const styles = StyleSheet.create({
    SubmitButtonStyle: {
        alignSelf:'center',
        width: 150,
        marginTop:30,
        paddingTop:15,
        paddingBottom:15,
        backgroundColor:'#f33160',
        borderWidth: 1,
        borderColor: '#fff'
    },
    TextStyle:{
        color:'#fff',
        textAlign:'center',
    },
    backgroundImage: {
        flex: 1,
        width: null,
        height: null,
    },
    backgroundImage2: {
        alignSelf: 'flex-start',
        left: 0
    },


});
