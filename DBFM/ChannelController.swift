import UIKit
import QuartzCore

protocol ChannelProtocol{
    //实现点击传回channel_id并更新主页面列表
    func onChangedChannel(channel_id:String)
}

class ChannelController: UIViewController , UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet var tv: UITableView
    //数据源
    var channelData:NSArray = NSArray()
    var delegate:ChannelProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int{
        return channelData.count
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!{
        //与外部cell相对应
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier:"channel")
        
        let rowData:NSDictionary = self.channelData[indexPath.row] as NSDictionary
        cell.textLabel.text = rowData["name"] as String
        return cell
    }
    
    //响应点击tableView事件
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!){
        //返回主页面函数
        //self.dismissViewControllerAnimated(true, completion: nil)
        //获取该单元格数据
        var rowData:NSDictionary = self.channelData[indexPath.row] as NSDictionary
        //获取channel_id
        var channel_id:AnyObject = rowData["channel_id"] as AnyObject
        //println("!!!!!!!!!!!!\(channel_id as String)")
        let surl:String = channel_id as String
        delegate?.onChangedChannel(surl)
        //返回主页面函数
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //展示单元格
    func tableView(tableView: UITableView!, willDisplayCell cell: UITableViewCell!, forRowAtIndexPath indexPath: NSIndexPath!){
        //单元格层的运动--初始状态
        cell.layer.transform = CATransform3DMakeScale(0.1, 0.1, 1)
        //单元格层的运动--结束状态
        UIView.animateWithDuration(0.25, animations: {
            cell.layer.transform = CATransform3DMakeScale(1, 1, 1)
            })
    }
    
}



