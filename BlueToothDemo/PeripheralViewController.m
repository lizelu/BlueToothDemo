//
//  PeripheralViewController.m
//  BlueToothDemo
//
//  Created by Mr.LuDashi on 15/12/2.
//  Copyright © 2015年 ZeluLi. All rights reserved.
//

#import "PeripheralViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

static NSString *const ServiceUUID1 =  @"FFF0";
static NSString *const notiyCharacteristicUUID =  @"FFF1";
static NSString *const LocalNameKey =  @"myPeripheral";

@interface PeripheralViewController () <CBPeripheralManagerDelegate>

@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (assign, nonatomic) NSInteger serviceNum;
@property (strong, nonatomic) NSTimer * timer;
@property (strong, nonatomic) IBOutlet UITextView *logTextView;
@property (strong, nonatomic) IBOutlet UITextField *userInputText;
@property (strong, nonatomic) CBCharacteristic *characteristic;


@end

@implementation PeripheralViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
}



- (IBAction)tapStopAdvertisingButton:(id)sender {
    [_peripheralManager stopAdvertising];
}
- (IBAction)tapSetUpButton:(id)sender {
    [self setUp];
}
- (IBAction)tapClearLog:(id)sender {
    _logTextView.text = @"";
}
- (IBAction)tapSendMessage:(id)sender {
    
    if (_characteristic != nil) {
        NSDateFormatter *dft = [[NSDateFormatter alloc]init];
        [dft setDateFormat:_userInputText.text];
       //执行回应Central通知数据
        [_peripheralManager updateValue:[[dft stringFromDate:[NSDate date]]
                                         dataUsingEncoding:NSUTF8StringEncoding]
                      forCharacteristic:(CBMutableCharacteristic *)_characteristic
                   onSubscribedCentrals:nil];

    }
}




- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    switch (peripheral.state) {
            //在这里判断蓝牙设别的状态  当开启了则可调用  setUp方法(自定义)
        case CBPeripheralManagerStatePoweredOn:
            [self showLog:[NSString stringWithFormat:@"设备名%@已经打开，可以使用center进行连接",LocalNameKey]];
            break;
        case CBPeripheralManagerStatePoweredOff:
            [self showLog:@"powered off"];
            break;
            
        default:
            break;
    }
}

//配置bluetooch的
-(void)setUp{
    //characteristics字段描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    
    /*
     可以通知的Characteristic
     properties：CBCharacteristicPropertyNotify
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *notiyCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:notiyCharacteristicUUID] properties:CBCharacteristicPropertyNotify | CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    
   
    //设置description
    CBMutableDescriptor *notiyCharacteristicDescription1 = [[CBMutableDescriptor alloc]initWithType: CBUUIDCharacteristicUserDescriptionStringUUID value:@"我是描述"];
    [notiyCharacteristic setDescriptors:@[notiyCharacteristicDescription1]];
    
    
    
    
    //service1初始化并加入两个characteristics
    CBMutableService *service1 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID1] primary:YES];
    [service1 setCharacteristics:@[notiyCharacteristic]];
    
    [_peripheralManager addService:service1];
}

/**
 *  perihpheral添加了service
 *
 *  @param peripheral 外设
 *  @param service    service
 *  @param error      error
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    
    NSArray *services = @[[CBUUID UUIDWithString:ServiceUUID1]];
    
    [_peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey : services,
                                              CBAdvertisementDataLocalNameKey : LocalNameKey}];
}

/**
 *  peripheral开始发送advertising
 *
 *  @param peripheral
 *  @param error
 */
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    [self showLog:@"peripheral开始发送advertising"];
}

/**
 *  订阅characteristics
 *
 *  @param peripheral
 *  @param central
 *  @param characteristic
 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    [self showLog:[NSString stringWithFormat:@"订阅了 %@的数据",characteristic.UUID]];
    _characteristic = characteristic;
//    //每秒执行一次给主设备发送一个当前时间的秒数
//    _timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(sendData:) userInfo:characteristic  repeats:YES];
}

/**
 *  取消订阅characteristics
 *
 *  @param peripheral
 *  @param central
 *  @param characteristic
 */
-(void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    [self showLog:[NSString stringWithFormat:@"取消订阅 %@的数据",characteristic.UUID]];
    //取消回应
    [_timer invalidate];
}

//发送数据，发送当前时间的秒数
-(BOOL)sendData:(NSTimer *)t {
    return YES;
//    CBMutableCharacteristic *characteristic = t.userInfo;
//    
//    NSDateFormatter *dft = [[NSDateFormatter alloc]init];
//    [dft setDateFormat:@"ss"];
//    [self showLog:[NSString stringWithFormat:@"%@",[dft stringFromDate:[NSDate date]]]];
//    
//    //执行回应Central通知数据
//    return  [_peripheralManager updateValue:[[dft stringFromDate:[NSDate date]]
//                                             dataUsingEncoding:NSUTF8StringEncoding]
//                          forCharacteristic:(CBMutableCharacteristic *)characteristic
//                       onSubscribedCentrals:nil];
    
}

/**
 *  读characteristics请求
 *
 *  @param peripheral
 *  @param request
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{
    [self showLog:@"didReceiveReadRequest"];
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        //对请求作出成功响应
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [_peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


/**
 *  写characteristics请求
 *
 *  @param peripheral
 *  @param requests
 */
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{

    CBATTRequest *request = requests[0];    
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        
        NSData *data = request.value;
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        [self showLog:string];
        
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        [_peripheralManager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [_peripheralManager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheral{
    [self showLog:@"peripheralManagerIsReadyToUpdateSubscribers"];
    
}

- (void)showLog:(NSString *)log {
    [NSString stringWithFormat:@""];
    NSString *tempStr = [NSString stringWithFormat:@"%@\n",_logTextView.text];
    NSString *resultStr = [tempStr stringByAppendingString:log];
    NSString *b =[resultStr stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
    _logTextView.text = b;
}

- (NSData *)stringToData:(NSString *)string {
    return  [string dataUsingEncoding:NSUTF8StringEncoding];
}


-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.view endEditing:NO];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
