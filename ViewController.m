//
//  ViewController.m
//  BluetoothPay
//
//  Created by zhao qinglei on 2017/4/18.
//  Copyright © 2017年 zhao qinglei. All rights reserved.
//
//导入.h文件和系统蓝牙库的头文件

#import "BabyBluetooth.h"
#import "ViewController.h"
#import "BabyToy.h"
#import  <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "SVProgressHUD.h"
#import "BaseButton.h"
#import "Archive.h"

//  请务必根据您所使用的设备来修改 UUID

#define kPeripheralUUID                 @"blueUUIDName"
#define kBlueMacValue                   @"fef384b72d3c"
#define kServiceUUID                    @"FFF0"
#define kCharacteristicUUIDName1        @"FFF1"//读写
#define kCharacteristicUUIDName2        @"FFF2"
#define kCharacteristicUUIDName3        @"FFF3"
#define kCharacteristicUUIDName4        @"FFF4"//广播
#define kCharacteristicUUIDName5        @"FFF5"
//#define kCharacteristicWriteNotifyUUID  @"49535343-ACA3-481C-91EC-D85E28A60318"



@interface ViewController ()
{

}
@property (nonatomic,strong) BabyBluetooth *babyBlue;
@property (nonatomic,strong) NSTimer *time;
@property (nonatomic,assign) BOOL isBlueConnect;    //是否开始蓝牙连接，默认YES
@property (nonatomic,assign) BOOL isBlueEnabled;    //蓝牙是否可用 YES可以，默认NO
@property (nonatomic,assign) BOOL isDeviceDistance; //是否满足距离条件，YES 是  NO 否 默认NO
@property (nonatomic,strong) NSData *writeData;
@property (nonatomic,assign) NSInteger countTag;





/********************************************
 *                 蓝牙
 ********************************************/

@property (nonatomic,strong) BabyBluetooth *baby;
@property (nonatomic,strong) CBPeripheral *myPeripheral;
@property(nonatomic, strong) CBCharacteristic* writeCharacteristic; //写特征


/********************************************
 *                 控件
 ********************************************/

@property (weak, nonatomic) IBOutlet UILabel *blueNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *character1Label;
@property (weak, nonatomic) IBOutlet UILabel *character2Label;
@property (weak, nonatomic) IBOutlet UILabel *character3Label;
@property (weak, nonatomic) IBOutlet UILabel *character4Label;
@property (weak, nonatomic) IBOutlet UILabel *character5Label;
@property (weak, nonatomic) IBOutlet UIButton *writeButton;
@property (weak, nonatomic) IBOutlet UITextField *writeTextField;
@property (weak, nonatomic) IBOutlet UILabel *readLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueStateLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueConnectStateLabel;
@property (weak, nonatomic) IBOutlet UIButton *autoButton;
@property (weak, nonatomic) IBOutlet UIButton *manualButton;


/********************************************
 *                 变量
 ********************************************/
@property (nonatomic,assign) NSInteger blueModeTag;
@property (weak, nonatomic) IBOutlet UITextView *logTextView;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //初始化BabyBluetooth 蓝牙库
    _baby = [BabyBluetooth shareBabyBluetooth];
     [self babyDelegate];
    [self initWithData];//初始设备数据
    

}


-(void)viewDidAppear:(BOOL)animated{
    NSLog(@"viewDidAppear");

}

#pragma mark - 初始化

-(void)initWithData
{
    
    _writeTextField.text  = @"30123456789987654387";
    _blueNameLabel.text   = @"获取中...";
    _character1Label.text = @"获取中...";
    _character2Label.text = @"获取中...";
    _character3Label.text = @"获取中...";
    _character4Label.text = @"获取中...";
    _character5Label.text = @"获取中...";
    _blueStateLabel.text  = @"获取中...";
    
    _blueModeTag = 1;//默认自动模式
    _writeTextField.enabled = NO;
    _writeButton.enabled = NO;
    

    _writeButton.backgroundColor = [UIColor grayColor];
    
    _isBlueConnect = YES;//标记位 ：可以进行新的一次蓝牙连接 为NO时说明上次连接没有结束
    _isBlueEnabled = NO;
    _isDeviceDistance = NO;
    


    
    [self listenDevicedistance:YES];//距离监听
    
    _logTextView.layoutManager.allowsNonContiguousLayout = NO;
    
}
#pragma mark- 蓝牙开始和结束
//开始连接连接
-(void)startBlueConnection
{
    if (!_isBlueEnabled) {//蓝牙不可以使用，不进行连接
        [self endBlueConnection];
        return;
        
    }
    
    if (!_isBlueConnect) {//蓝牙正在处理中，不进行连接
         [self endBlueConnection];
        return;
    }
    
//    if (_blueModeTag == 2) {//手动模式
//         [_baby cancelAllPeripheralsConnection];//断开连接
//    }


     _isBlueConnect = NO;//标记蓝牙连接处理中
    
    NSString *uuisString = [[NSUserDefaults standardUserDefaults] objectForKey:kPeripheralUUID];
    
    if (uuisString == nil || [uuisString isEqualToString:@""]) {
        NSLog(@"=== 第一次连接，进入搜索蓝牙模式 ===");
        [self showlonView:@"第一次连接，进入搜索蓝牙模式"];
        _baby.scanForPeripherals().begin();
    }else
    {
        _blueNameLabel.text = @"直接模式不捕获名称";
        [self showlonView:@"=== 蓝牙信息已存储，进入直连模式 ===="];
        NSLog(@"蓝牙信息已存储，进入直连模式");
//         _baby.scanForPeripherals().begin();
//        return;
        _myPeripheral = [_baby retrievePeripheralWithUUIDString:uuisString];
        _baby.having(_myPeripheral).and.then.connectToPeripherals().discoverServices().discoverCharacteristics().begin();
        
    }

}

//结束蓝牙连接
-(void)endBlueConnection
{
    _isBlueConnect = YES;
    _isDeviceDistance = NO;

    [_baby cancelAllPeripheralsConnection];//断开连接
    _writeCharacteristic = nil;
    _myPeripheral = nil;
    
}

#pragma mark - 监听距离传感器
- (void)proximityStateDidChange
{

    if ([UIDevice currentDevice].proximityState) {
        
        NSLog(@"有物品靠近");
        [self showlonView:@"靠近蓝牙设备附近"];
        
        //开始进行蓝牙连接
        if (_isBlueConnect) {//标记蓝牙发送是否结束
            _isDeviceDistance = YES;    //满足距离条件
             [self showlonView:@"连接蓝牙中...."];
            [self startBlueConnection];
        }
        
    } else {
        NSLog(@"有物品离开");
         [self showlonView:@"离开蓝牙设备附近"];
    }
}




#pragma mark - -----------  第三方蓝牙方法 --------------
#pragma mark 设置蓝牙委托
-(void)babyDelegate
{
    __weak typeof(self) weakSelf = self;
   
#pragma mark 设备监听
    //设备状态改变的委托
    [_baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        NSLog(@"设备状态改变");
        if (central.state == CBCentralManagerStatePoweredOn) {
            _isBlueEnabled = YES;
            weakSelf.blueStateLabel.text = @"蓝牙已开启";
            
            [SVProgressHUD showInfoWithStatus:@"蓝牙已开启"];
            
            //停止之前的连接
            [weakSelf.baby cancelAllPeripheralsConnection];

        }
         if (central.state == CBCentralManagerStatePoweredOff)
         {
             weakSelf.blueStateLabel.text = @"蓝牙未开启";
             NSLog(@"可用，未打开");
             _isBlueEnabled = NO;
         }
        if (central.state == CBCentralManagerStateUnsupported)
        {
            weakSelf.blueStateLabel.text = @"SDK不支持";
            NSLog(@"SDK不支持");
            _isBlueEnabled = NO;
        }
        if (central.state == CBCentralManagerStateUnauthorized)
        {
            weakSelf.blueStateLabel.text = @"程序未授权";
            _isBlueEnabled = NO;
            NSLog(@"程序未授权");
        }
        if (central.state == CBCentralManagerStateResetting)
        {
            _isBlueEnabled = NO;
            NSLog(@"CBCentralManagerStateResetting");
        }
        if (central.state == CBCentralManagerStateUnknown)
        {
            _isBlueEnabled = NO;
            NSLog(@"CBCentralManagerStateUnknown");
        }
    }];
    
    
#pragma mark 设备检索
    //找到Peripherals的委托
    [_baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        // 保存扫描到得外部设备
        // 判断如果数组中不包含当前扫描到得外部设置才保存
        
        [weakSelf showlonView:@"设备检索中..."];
        [weakSelf showlonView:[NSString stringWithFormat:@"设备名称:%@",peripheral.name]];
        [weakSelf showlonView:[NSString stringWithFormat:@"设备UUID:%@",peripheral.identifier.UUIDString]];
        
        NSLog(@"设备名称:%@ \n 设备唯一标识:%@",peripheral.name, peripheral.identifier.UUIDString);

        NSData *adMacdata = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
      
        if (adMacdata.length >0) {
            NSString *adMacString= [weakSelf convertDataToHexStr:adMacdata];
            NSLog(@"mac 地址:%@",adMacString);
            [weakSelf showlonView:[NSString stringWithFormat:@"== MAC:%@ ==",adMacString]];
            [SVProgressHUD showInfoWithStatus:@"开始连接设备"];
            
            if ([adMacString isEqualToString:kBlueMacValue])
            {
                [[NSUserDefaults standardUserDefaults] setObject:peripheral.identifier.UUIDString forKey:kPeripheralUUID];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                weakSelf.blueNameLabel.text = peripheral.name;
                weakSelf.myPeripheral = peripheral;
                 weakSelf.baby.having(peripheral).and.then.connectToPeripherals().discoverServices().discoverCharacteristics().begin();
                
//                weakSelf.baby.having(peripheral).and.then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
                
                [weakSelf.baby cancelScan];
            }

        }
        
        return ;
        
          }];
    
#pragma mark 蓝牙连接成功
    //连接Peripherals成功的委托
    [_baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        NSLog(@"设备连接成功");
        
        NSString *longString = [NSString stringWithFormat:@"蓝牙连接成功"];
        [weakSelf showlonView:longString];
        weakSelf.blueConnectStateLabel.text = @"蓝牙连接成功";
        
    }];
    
#pragma mark 蓝牙连接失败
    //连接Peripherals失败的委托
    [_baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备连接失败");
         weakSelf.blueConnectStateLabel.text = @"蓝牙连接失败";
        [weakSelf endBlueConnection];
        
    }];
    
#pragma mark 断开连接
    //断开Peripherals的连接
    [_baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备连接断开");
         weakSelf.blueConnectStateLabel.text = @"蓝牙连接断开";
         [weakSelf showlonView:@"设备连接断开"];
    }];
    
    //设置查找服务回叫
    [_baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        NSLog(@"查找服务回调");
    }];
    
#pragma mark 查找特征
    //设置查找到Characteristics的block
    [_baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
        NSLog(@"查找特征回调");
        NSLog(@"===service name:%@",service.UUID);
        if (![service.UUID.UUIDString isEqualToString:kServiceUUID]) {//FFF0
            return ;
        }
        
        for (CBCharacteristic *characteristic in service.characteristics) {//遍历
            NSLog(@"charateristic name is :%@",characteristic.UUID);
            
            
            if ([characteristic.UUID.UUIDString isEqualToString:kCharacteristicUUIDName1]) {
                weakSelf.writeCharacteristic = characteristic;
                weakSelf.myPeripheral = peripheral;
                NSLog(@"获取到可写的的特征");
                
                weakSelf.character1Label.text = [NSString stringWithFormat:@"FFF1 读写特性"];
                
                if(weakSelf.blueModeTag == 1)//自动模式
                {
                    if(weakSelf.isDeviceDistance)//满足距离条件，发送消息
                    {
                        [weakSelf startWriteBlue];
                    }
                    
                }
                if(weakSelf.blueModeTag == 2)//手动模式
                {
                    [weakSelf startWriteBlue];
                }
                
            }
            if ([characteristic.UUID.UUIDString isEqualToString:kCharacteristicUUIDName2]) {
                 weakSelf.character2Label.text = [NSString stringWithFormat:@"FFF2 具备读特性"];
                
            }
            if ([characteristic.UUID.UUIDString isEqualToString:kCharacteristicUUIDName3]) {
                weakSelf.character3Label.text = [NSString stringWithFormat:@"FFF3 具备写入值的特性"];
                
            }
            if ([characteristic.UUID.UUIDString isEqualToString:kCharacteristicUUIDName4]) {//广播特征
                weakSelf.character4Label.text = [NSString stringWithFormat:@"FFF4 具备广播特性"];
                [peripheral setNotifyValue:YES forCharacteristic:characteristic];//监听这个特征
                
            }
            if ([characteristic.UUID.UUIDString isEqualToString:kCharacteristicUUIDName5]) {
                weakSelf.character5Label.text = [NSString stringWithFormat:@"FFF5 具备读特性"];
            }

        }
        
    }];
    
    //设置获取到最新Characteristics值的block
    [_baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"获取最新特征回调");
    }];
    
    //设置查找到Characteristics描述的block
    [_baby setBlockOnDiscoverDescriptorsForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"查找到特征描述");
    }];
    
    
    //设置读取到Characteristics描述的值的block
    [_baby setBlockOnReadValueForDescriptors:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) {
        NSLog(@"查找特征描述值的回调");
    }];
    
    
    //写Characteristic成功后的block
#pragma mark 写入数据成功
    [_baby setBlockOnDidWriteValueForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"写入数据成功");
        [weakSelf showlonView:@"写入数据完成"];
        [weakSelf endBlueConnection];
    }];
    
    
    //写descriptor成功后的block
    [_baby setBlockOnDidWriteValueForDescriptor:^(CBDescriptor *descriptor, NSError *error) {
        NSLog(@"写描述成功");
    }];
    
    //characteristic订阅状态改变的block
    [_baby setBlockOnDidUpdateNotificationStateForCharacteristic:^(CBCharacteristic *characteristic, NSError *error) {
        NSLog(@"特征订阅状态改变");
        NSString *result = [weakSelf convertDataToHexStr:characteristic.value];
        NSLog(@"收到蓝牙数据：%@",result);
        if (![characteristic.UUID.UUIDString isEqualToString:kCharacteristicUUIDName4]) {//只处理广播数据
            NSLog(@"蓝牙数据不是广播的过滤");
            return;
        }
        
        weakSelf.readLabel.text = result;
        

    }];
    
    
    //读取RSSI的委托
    [_baby setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) {
        NSLog(@"读取RSSI:%d",RSSI.intValue);
    }];
    
    
    //扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES,
                                                    CBCentralManagerOptionShowPowerAlertKey:@YES};
    /*连接选项->
     CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
     */
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@NO,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@NO,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@NO};
    
    
    //连接设备属性设置
    [_baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:connectOptions scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
    
    
}

- (NSString *)convertDataToHexStr:(NSData *)data {
    if (!data || [data length] == 0) {
        return @"";
    }
    NSMutableString *string = [[NSMutableString alloc] initWithCapacity:[data length]];
    
    [data enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop) {
        unsigned char *dataBytes = (unsigned char*)bytes;
        for (NSInteger i = 0; i < byteRange.length; i++) {
            NSString *hexStr = [NSString stringWithFormat:@"%x", (dataBytes[i]) & 0xff];
            if ([hexStr length] == 2) {
                [string appendString:hexStr];
            } else {
                [string appendFormat:@"0%@", hexStr];
            }
        }
    }];
    
    return string;
}


#pragma mark- 按钮写入事件
- (IBAction)writeButtonAction:(id)sender {
    
    [self startBlueConnection];

}

#pragma mark - UITextField 

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    //返回一个BOOL值，指定是否循序文本字段开始编辑
    
    return YES;
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    //返回一个BOOL值，指明是否允许在按下回车键时结束编辑
    
    //如果允许要调用resignFirstResponder 方法，这回导致结束编辑，而键盘会被收起
    
    [textField resignFirstResponder];//查一下resign这个单词的意思就明白这个方法了
    
    return YES;
    
    
}

- (void)textFieldDidChange:(UITextField *)textField
{

    if (textField.text.length > 20) {
        textField.text = [textField.text substringToIndex:20];
    }
    
}


#pragma mark -  蓝牙写入

-(void)startWriteBlue
{
  
    NSLog(@"开始写入数据");
    if (_writeCharacteristic != nil && _myPeripheral != nil)
    {
        [self showlonView:@"开始写入数据"];
        NSString *writeString = _writeTextField.text;
        
        NSData *data = [writeString dataUsingEncoding:NSUTF8StringEncoding];
        [_myPeripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithResponse];
        
    }
    
}

#pragma mark - UI 特性显示


-(void)countCharText:(NSString*)text count:(NSInteger)count
{
    
    switch (count) {
        case 1:
            _character1Label.text = text;
            break;
        case 2:
            _character2Label.text = text;
            break;
        case 3:
            _character3Label.text = text;
            break;
        case 4:
            _character4Label.text = text;
            break;
        case 5:
            _character5Label.text = text;
            break;
            
        default:
            break;
    }
}


#pragma mark -  自动 手动 模式
- (IBAction)blueModeSwitchButtonAction:(id)sender {
    UIButton *button = (UIButton *)sender;
    
    if (button.tag == _blueModeTag) {//点击的就是当前选择的模式
        return;
    }
    
    switch (button.tag) {
        case 1://切换成自动模式
        {
            [_autoButton setBackgroundImage:[UIImage imageNamed:@"btn_radio_selected"] forState:UIControlStateNormal];
            [_manualButton setBackgroundImage:[UIImage imageNamed:@"btn_radio"] forState:UIControlStateNormal];

            _writeTextField.enabled = NO;
            _writeButton.enabled = NO;
            _writeButton.backgroundColor = [UIColor grayColor];
             [self listenDevicedistance:YES];
            
        }
            break;
        case 2://切换成手动模式
        {
             [_manualButton setBackgroundImage:[UIImage imageNamed:@"btn_radio_selected"] forState:UIControlStateNormal];
            [_autoButton setBackgroundImage:[UIImage imageNamed:@"btn_radio"] forState:UIControlStateNormal];
            
            _writeTextField.enabled = YES;
            _writeButton.enabled = YES;
            
           _writeButton.backgroundColor= UIColorFromRGB(k_Color_Button);
            [self listenDevicedistance:NO];
        }
            break;
            
        default:
            break;
    }
    _blueModeTag = button.tag;
}


#pragma mark- 监听距离
-(void)listenDevicedistance:(BOOL)monitor
{
    UIDevice *device = [UIDevice currentDevice];
    [device setProximityMonitoringEnabled:monitor];
    
    if (monitor) {
        // 监听有物品靠近还是离开
        if ([device isProximityMonitoringEnabled]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(proximityStateDidChange)
                                                         name:UIDeviceProximityStateDidChangeNotification object:nil];
        }else {
            NSLog(@"No Proximity Sensor");
        }
    }
    
   
}


#pragma mark - 日志
-(void)showlonView:(NSString*)logString
{
    if (_logTextView.text.length >=2000) {
        _logTextView.text = @"";
    }
    
    NSMutableString *tempString = [[NSMutableString alloc] initWithString:_logTextView.text];
    [tempString appendString:@"\n"];
    [tempString appendString:logString];
    _logTextView.text= tempString;
    [_logTextView scrollRangeToVisible:NSMakeRange(_logTextView.text.length, 1)];
    
     
}

#pragma mark- 懒加载
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
