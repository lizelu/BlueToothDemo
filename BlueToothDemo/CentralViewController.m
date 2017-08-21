//
//  ViewController.m
//  BlueToothDemo
//
//  Created by Mr.LuDashi on 15/12/1.
//  Copyright © 2015年 ZeluLi. All rights reserved.
//

#import "CentralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralViewController ()<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSArray *characteristics;
@property (strong, nonatomic) IBOutlet UITextView *LogTextView;
@property (strong, nonatomic) IBOutlet UIButton *orderButton;
@property (strong, nonatomic) IBOutlet UIButton *unOrderButton;
@property (strong, nonatomic) IBOutlet UIButton *stopScan;
@property (strong, nonatomic) IBOutlet UIButton *stopConnect;
@property (strong, nonatomic) IBOutlet UITextField *userInputTextField;

@end

@implementation CentralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
    [self showLog:@"正在执行程序，请观察NSLog信息"];
    _orderButton.enabled = NO;
    _unOrderButton.enabled = NO;
    _stopScan.enabled = NO;
    _stopConnect.enabled = NO;
}



#pragma mark -- Event Response
/**
 *  扫描周围的设备
 *
 *  @param sender
 */
- (IBAction)tapScanner:(id)sender {
    [_centralManager scanForPeripheralsWithServices:nil options:nil];
    _stopScan.enabled = YES;
}

/**
 *  点击连接
 *
 *  @param sender
 */
- (IBAction)tapConnect:(id)sender {
    if (_peripheral != nil) {
        [_centralManager connectPeripheral:_peripheral options:nil];
    }
}

/**
 *  清空日志
 *
 *  @param sender
 */
- (IBAction)clearLog:(id)sender {
    _LogTextView.text = @"";
}

/**
 *  订阅外设消息
 *
 *  @param sender
 */
- (IBAction)tapOrderButton:(id)sender {
    if (_peripheral != nil && _characteristics != nil) {
        [self notifyCharacteristic:_peripheral characteristic:_characteristics[0]];
        _unOrderButton.enabled = YES;
    }
}

/**
 *  取消订阅外设消息
 *
 *  @param sender
 */
- (IBAction)tapUnOrderButton:(id)sender {
    if (_peripheral != nil && _characteristics != nil) {
        [self cancelNotifyCharacteristic:_peripheral characteristic:_characteristics[0]];
        _unOrderButton.enabled = YES;
    }

}

/**
 *  停止扫描
 *
 *  @param sender <#sender description#>
 */
- (IBAction)tapStopScan:(id)sender {
    [_centralManager stopScan];
}

/**
 *  断开连接
 *
 *  @param sender
 */
- (IBAction)stopConnect:(id)sender {
    [_centralManager cancelPeripheralConnection:_peripheral];
}

/**
 *  写数据
 *
 *  @param sender
 */
- (IBAction)tapWriteButton:(id)sender {
    NSString *text = _userInputTextField.text;
    if (![text isEqualToString:@""]) {
        NSData *data = [text dataUsingEncoding:NSUTF8StringEncoding];
        [self writeCharacteristic:_peripheral characteristic:_characteristics[0] value:data];
    }
}



#pragma mark -- CBCentralManagerDelegate
/**
 *  更新蓝牙状态要调用的方法
 *
 *  @param central centralManager
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    switch (central.state) {
        case CBCentralManagerStateUnknown:
            [self showLog:@">>>CBCentralManagerStateUnknown"];
            break;
        case CBCentralManagerStateResetting:
             [self showLog:@">>>CBCentralManagerStateResetting"];
            break;
        case CBCentralManagerStateUnsupported:
             [self showLog:@">>>CBCentralManagerStateUnsupported"];
            break;
        case CBCentralManagerStateUnauthorized:
             [self showLog:@">>>CBCentralManagerStateUnauthorized"];
            break;
        case CBCentralManagerStatePoweredOff:
             [self showLog:@">>>CBCentralManagerStatePoweredOff"];
            break;
        case CBCentralManagerStatePoweredOn:
             [self showLog:@">>>CBCentralManagerStatePoweredOn"];
            break;
        default:
            break;
    }
}

/**
 *  扫描到设备会进入方法
 *
 *  @param central           中央设备管理
 *  @param peripheral        外设
 *  @param advertisementData
 *  @param RSSI
 */
-(void)centralManager:(CBCentralManager *)central
didDiscoverPeripheral:(CBPeripheral *) peripheral
    advertisementData:(NSDictionary *) advertisementData
                 RSSI:(NSNumber *)RSSI {
    
    if ([peripheral.name isEqualToString:@"李泽鲁"]){
        _peripheral = peripheral;
        [self showLog:[NSString stringWithFormat:@"peripheralName === %@\n ",peripheral]];
        [self showLog:[NSString stringWithFormat: @"advertisementData === %@\n", advertisementData]];
        [self showLog:[NSString stringWithFormat: @"RSSI === %@\n\n", RSSI]];
    }
}

/**
 *  连接到Peripherals-成功
 *
 *  @param central
 *  @param peripheral
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    _stopConnect.enabled = YES;
    [self showLog:[NSString stringWithFormat:@">>>连接到名称为（%@）的设备-成功",peripheral.name]];
    [peripheral setDelegate:self];
    [peripheral discoverServices:nil];
}

/**
 *  连接到Peripherals-失败
 *
 *  @param central
 *  @param peripheral
 *  @param error
 */
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
     [self showLog:[NSString stringWithFormat:@">>>连接到名称为（%@）的设备-失败,原因:%@",[peripheral name],[error localizedDescription]]];
}

/**
 *  Peripherals断开连接
 *
 *  @param central
 *  @param peripheral
 *  @param error
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
     [self showLog:[NSString stringWithFormat:@">>>外设连接断开连接 %@: %@\n", [peripheral name], [error localizedDescription]]];
    
}




#pragma mark -- CBPeripheralDelegate
/**
 *  扫描服务后调用的方法
 *
 *  @param peripheral 外设
 *  @param error      错误信息
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    if (error) {
         [self showLog:[NSString stringWithFormat:@">>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]]];
        return;
    }
    
    for (CBService *service in peripheral.services) {
         [self showLog:[NSString stringWithFormat:@"服务:%@\n",service]];
        [peripheral discoverCharacteristics:nil forService:service];
    }
    [self showLog:@"\n\n"];
    
}

/**
 *  扫描到Characteristics
 *
 *  @param peripheral peripheral description
 *  @param service    service description
 *  @param error      error description
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error) {
         [self showLog:[NSString stringWithFormat:@"error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]]];
        return;
    }
    
    NSString *serviceUUID = [NSString stringWithFormat:@"%@", service.UUID];
    NSLog(@"%@", serviceUUID);
    if ([serviceUUID isEqualToString:@"FFF0"]) {
        self.characteristics = service.characteristics;
        _orderButton.enabled = YES;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics) {
         [self showLog:[NSString stringWithFormat:@"service:%@ 的 Characteristic: \n%@\n",service.UUID,characteristic]];
    }
    
    //获取Characteristic的值
    for (CBCharacteristic *characteristic in service.characteristics){
            [peripheral readValueForCharacteristic:characteristic];
    }

    //搜索Characteristic的Descriptors
    for (CBCharacteristic *characteristic in service.characteristics){
        [peripheral discoverDescriptorsForCharacteristic:characteristic];
    }
    
    
}

/**
 *  获取的charateristic的值
 *
 *  @param peripheral
 *  @param characteristic
 *  @param error
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    //打印出characteristic的UUID和值
    //!注意，value的类型是NSData，具体开发时，会根据外设协议制定的方式去解析数据
    NSData *data = characteristic.value;
    if (data != nil) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self showLog:string];
    }
    
}

/**
 *  搜索到Characteristic的Descriptors
 *
 *  @param peripheral
 *  @param characteristic
 *  @param error
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    //打印出Characteristic和他的Descriptors
     [self showLog:[NSString stringWithFormat:@"characteristic:%@\n",characteristic]];
    for (CBDescriptor *d in characteristic.descriptors) {
         [self showLog:[NSString stringWithFormat:@"Descriptor:%@\n", d]];
    }
    
}
/**
 *  获取到Descriptors的值
 *
 *  @param peripheral
 *  @param descriptor
 *  @param error
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error{
    [self showLog:[NSString stringWithFormat:@"descriptor :%@", descriptor]];
}

/**
 *  写数据
 *
 *  @param peripheral     peripheral description
 *  @param characteristic characteristic description
 *  @param value          value description
 */
-(void)writeCharacteristic:(CBPeripheral *) peripheral
            characteristic:(CBCharacteristic *) characteristic
                     value:(NSData *)value {
    
    //打印出 characteristic 的权限，可以看到有很多种，这是一个NS_OPTIONS，就是可以同时用于好几个值，常见的有read，write，notify，indicate，知知道这几个基本就够用了，前连个是读写权限，后两个都是通知，两种不同的通知方式。
    /*
     typedef NS_OPTIONS(NSUInteger, CBCharacteristicProperties) {
     CBCharacteristicPropertyBroadcast												= 0x01,
     CBCharacteristicPropertyRead													= 0x02,
     CBCharacteristicPropertyWriteWithoutResponse									= 0x04,
     CBCharacteristicPropertyWrite													= 0x08,
     CBCharacteristicPropertyNotify													= 0x10,
     CBCharacteristicPropertyIndicate												= 0x20,
     CBCharacteristicPropertyAuthenticatedSignedWrites								= 0x40,
     CBCharacteristicPropertyExtendedProperties										= 0x80,
     CBCharacteristicPropertyNotifyEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)		= 0x100,
     CBCharacteristicPropertyIndicateEncryptionRequired NS_ENUM_AVAILABLE(NA, 6_0)	= 0x200
     };
     
     */
     [self showLog:[NSString stringWithFormat:@"%lu", (unsigned long)characteristic.properties]];
    
    
    //只有 characteristic.properties 有write的权限才可以写
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        /*
         最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,区别是是否会有反馈
         */
        [peripheral writeValue:value forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }else{
         [self showLog:@"该字段不可写！"];
    }
    
    
}

/**
 *  设置通知
 *
 *  @param peripheral
 *  @param characteristic
 */
-(void)notifyCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic{
    //设置通知，数据通知会进入：didUpdateValueForCharacteristic方法
    [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    
}

/**
 *  取消通知
 *
 *  @param peripheral
 *  @param characteristic 
 */
-(void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                   characteristic:(CBCharacteristic *)characteristic{
    
    [peripheral setNotifyValue:NO forCharacteristic:characteristic];
}


- (void)showLog:(NSString *)log {
    if (log != nil) {
        [NSString stringWithFormat:@""];
        NSString *tempStr = [NSString stringWithFormat:@"%@\n",_LogTextView.text];
        NSString *resultStr = [tempStr stringByAppendingString:log];
        NSString *b =[resultStr stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        _LogTextView.text = b;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:NO];
}

@end
