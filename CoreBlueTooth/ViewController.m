//
//  ViewController.m
//  CoreBlueTooth
//
//  Created by 小飞鸟 on 2018/1/27.
//  Copyright © 2018年 小飞鸟. All rights reserved.
//

#import "ViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>
@interface ViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@end

@implementation ViewController{
    
    CBCentralManager * mgr;
    //外部设备数组  被发现的外设数组
    NSMutableArray * deviceArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    deviceArr =[NSMutableArray array];
    mgr =[[CBCentralManager alloc]initWithDelegate:self queue:nil];// queue 传nil  主队列
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [mgr stopScan];//停止设备扫描
}

#pragma mark 蓝牙设备的当前状态  只要中心管理者初始化,就会触发此代理方法  中心管理器的状态
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    
    /**
     CBManagerStateUnknown = 0,//不识别的
     CBManagerStateResetting,//重置
     CBManagerStateUnsupported,//不支持
     CBManagerStateUnauthorized,//不授权的
     CBManagerStatePoweredOff,//未开启
     CBManagerStatePoweredOn,//开启了的
     */
    /****中心设备当前的蓝牙连接状态*****/
    switch (central.state) {
            
        case CBManagerStateUnknown:
            NSLog(@"中心管理器状态未知");
            break;
        case CBManagerStateResetting:
            NSLog(@"中心管理器状态重置");
            break;
        case CBManagerStateUnsupported:
            NSLog(@"中心管理器状态不被支持");
            break;
        case CBManagerStateUnauthorized:
            NSLog(@"中心管理器状态未被授权");
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"中心管理器状态电源关闭");
            break;
        case CBManagerStatePoweredOn:
            //2、扫描外设    在中心管理者成功开启后开始搜索外设
            [mgr scanForPeripheralsWithServices:nil options:nil];
            break;
            
        default:
            break;
    }
    
}



#pragma mark 过滤外设,进行连接
/**
 //链接外部设备

 @param central 中心设备
 @param peripheral 外部设备
 @param advertisementData 相关数据
 @param RSSI 信号强度
 */
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI{
    //1.记录设备 使用数组
    if (![deviceArr containsObject:peripheral]) {
        [deviceArr addObject:peripheral];
    }
    //2、执照tableview表格
    //3.链接外围设备
    [mgr connectPeripheral:peripheral options:nil];
    //4.设置外设的代理
    peripheral.delegate=self;
    //判断外设是不是我们需要连接的外设
    if ([peripheral.name hasPrefix:@"XXX"] && (ABS(RSSI.integerValue) > 35)) {
        // 标记我们的外设,延长他的生命周期
//        self.peripheral = peripheral;
        // 进行连接
        [mgr connectPeripheral:peripheral options:nil];
    }
}

#pragma Mark 连接状态(成功,失败,断开)
//链接到外部设备之后  回调这个代理方法  中心管理者连接外设成功,连接成功之后,可以进行服务和特征的发现
-(void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    
    //扫描服务 nil->扫描所有的服务
    [peripheral discoverServices:nil];
    
}
#pragma Mark 外设连接失败
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    NSLog(@"%@连接失败",peripheral.name);
}
#pragma Mark  丢失连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@断开连接",peripheral.name);
}



#pragma mark 发现服务以及内部的特征
/**发现外设的服务后调用的方法*/
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    // 判断没有失败
    if (error) {
        NSLog(@"error:%@",error.localizedDescription);
        return;
    }
    
    //获取外设的服务
    for(CBService * service in peripheral.services){
        
        if ([service.UUID.UUIDString isEqualToString:@"UUID值"]) {
            //如果UUID一致 开始扫描特征 nil->所有的特征
            [peripheral discoverCharacteristics:nil forService:service];
        }
        
    }
    
}

#pragma mark 发现服务后,让设备再发现服务内部的特征
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    //获取外设的服务的特征
    for(CBCharacteristic *  characteristic in service.characteristics){
        
        if ([characteristic.UUID.UUIDString isEqualToString:@"UUID值"]) {
            //数据操作
            [peripheral readValueForCharacteristic:characteristic];//读取操作
            //[peripheral writeValue:<#(nonnull NSData *)#> forDescriptor:<#(nonnull CBDescriptor *)#>];
            // 获取特征对应的描述
            [peripheral discoverDescriptorsForCharacteristic:characteristic];
            // 获取特征的值
            [peripheral readValueForCharacteristic:characteristic];
            
        }
        
    }
    
}
#pragma mark 更新特征
// 更新特征的描述的值的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    
    [peripheral readValueForDescriptor:descriptor];
}

// 更新特征的value的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        [peripheral readValueForDescriptor:descriptor];
    }
}

#pragma mark 外设写数据到特征中
// 更新特征的描述的值的时候会调用
- (void)peripheral:(CBPeripheral *)peripheral didWriteData:(NSData *)data forCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    
    //
    if (characteristic.properties & CBCharacteristicPropertyWrite) {
        // 下面方法中参数的意义依次是:写入的数据 写给哪个特征 通过此响应记录是否成功写入
        [peripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }
}

#pragma mark 通知的订阅和取消订阅
- (void)peripheral:(CBPeripheral *)peripheral regNotifyWithCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    // 外设为特征订阅通知
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
}
- (void)peripheral:(CBPeripheral *)peripheral CancleRegNotifyWithCharacteristic:(nonnull CBCharacteristic *)characteristic
{
    // 外设取消订阅通知
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}

- (void)dismissConentedWithPeripheral:(CBPeripheral *)peripheral
{
    // 停止扫描
    [mgr stopScan];
    // 断开连接
    [mgr cancelPeripheralConnection:peripheral];
}




@end
