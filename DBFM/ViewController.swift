import UIKit
import MediaPlayer
import QuartzCore//视觉效果

class ViewController: UIViewController ,UITableViewDataSource ,UITableViewDelegate ,HttpProtocol,ChannelProtocol{
    
    @IBOutlet var tv: UITableView
    @IBOutlet var iv: UIImageView
    @IBOutlet var progressView: UIProgressView
    @IBOutlet var playTim: UILabel
    @IBOutlet var btnPlay: UIImageView
    @IBOutlet var tap: UITapGestureRecognizer = nil
    
    var eHttp :HttpController = HttpController()
    ///////////////////存储接收到的数据////////////
    //主界面
    var tableData:NSArray = NSArray()
    //频道列表
    var channelData:NSArray = NSArray()
    //存储歌曲缩略图
    var imageCache = Dictionary<String,UIImage>()
    //播放器
    var audioPlayer:MPMoviePlayerController = MPMoviePlayerController()
    //时间控制器
    var timer:NSTimer?
    
    @IBAction func onTap(sender: UITapGestureRecognizer) {
        //println("tap")
        if sender.view == btnPlay{
            btnPlay.hidden = true
            iv.hidden = false
            audioPlayer.play()
            btnPlay.removeGestureRecognizer(tap)
            iv.addGestureRecognizer(tap)
        }
        else if sender.view == iv{
            iv.hidden = true
            btnPlay.hidden = false
            audioPlayer.pause()
            iv.removeGestureRecognizer(tap)
            btnPlay.addGestureRecognizer(tap)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        eHttp.delegate = self
        //频道列表
        eHttp.onSearch("http://www.douban.com/j/app/radio/channels")
        //默认频道歌曲列表
        eHttp.onSearch("http://douban.fm/j/mine/playlist?channel=0")
        //progressView.setProgress(0, animated: true)
        progressView.progress = 0.0
        iv.addGestureRecognizer(tap)//将iv与tap相关联
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //当页面跳转时将channelData的数据传递给ChannelController
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        var channelController :ChannelController = segue.destinationViewController as ChannelController
        channelController.delegate = self
        channelController.channelData = self.channelData
    }
    /*
    func tableView(tableView: UITableView!, heightForRowAtIndexPath indexPath: NSIndexPath!) -> CGFloat{
        return 25
    }*/
    
    //填充数据，返回填充数据个数
    func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int{
        //println("!!!!!!!!!!!!!!!!!!!!!!!!\(tableData.count)")
        return tableData.count
        //return 1
    }
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    //设置每个单元格内数据
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell!{
        let cell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier:"DFFM")

        let rowData:NSDictionary = self.tableData[indexPath.row] as NSDictionary //获取行数据
        cell.textLabel.text = rowData["title"] as String //歌曲名称
        cell.detailTextLabel.text = rowData["artist"] as String //歌手名称
        cell.imageView.image = UIImage(named: "detail.jpg") //缩略图
        
        let url = rowData["picture"] as String
        let image = self.imageCache[url] as? UIImage //从imageCache中获取图片
        if !image?{
            //如果缓存中没有 从网络中获取
            let imgUrl = NSURL(string: url)
            let request:NSURLRequest = NSURLRequest(URL: imgUrl)
            //异步获取
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
                (response:NSURLResponse!,data:NSData!,error:NSError!) -> Void in
                let img = UIImage(data: data)
                cell.imageView.image = img
                self.imageCache[url] = img //将获取到的缩略图放入imageCache中
                
                })
        }
        else{
            cell.imageView.image = image
        }
        
        return cell
    }
    
    //响应点击tableView事件
    func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!){
        //返回主页面函数
        //self.dismissViewControllerAnimated(true, completion: nil)
        if iv.hidden == true{
            btnPlay.hidden = true
            btnPlay.removeGestureRecognizer(tap)
            iv.addGestureRecognizer(tap)
        }
        
        var rowData:NSDictionary = self.tableData[indexPath.row] as NSDictionary
        
        //歌曲Url
        let audioUrl:String = rowData["url"] as String
        self.onSetAudio(audioUrl)
        //图片Url
        let picUrl = rowData["picture"] as String
        self.onSetImage(picUrl)
        iv.hidden = false
    }
    
    func didRecieveResult(result:NSDictionary){
        //println("===============================")
        //println(result)
        if result["song"]{
            //歌曲数据——tableData
            self.tableData = result["song"] as NSArray
            self.tv.reloadData()
            //获取数据后 默认播放第一条音乐
            let firDict:NSDictionary = self.tableData[0] as NSDictionary
            //歌曲Url
            let audioUrl:String = firDict["url"] as String
            self.onSetAudio(audioUrl)
            //图片Url
            let picUrl = firDict["picture"] as String
            self.onSetImage(picUrl)
            
        }
        else if result["channels"]{
            //频道列表数据
            self.channelData = result["channels"] as NSArray
            //self.tv.reloadData()
        }
    }
    //设置音乐
    func onSetAudio(url:String){
        timer?.invalidate()
        playTim.text = "00:00"
        self.audioPlayer.stop()
        self.audioPlayer.contentURL = NSURL(string: url)
        self.audioPlayer.play()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "onUpdate", userInfo: nil, repeats: true)
    }
    
    //进度条更新
    func onUpdate(){
        //获取当前时间
        let c = audioPlayer.currentPlaybackTime
        if c>0{
            //总时间
            let p = audioPlayer.duration
            //计算百分比
            var per = CFloat(c / p)
            progressView.setProgress(per, animated: true)
            //playTim.text = String(c)
            //总秒数
            var totalSec = Int(c)
            //min
            var min = totalSec / 60
            //sec
            var sec = totalSec % 60
            var time:String
            if min < 10{
                time = "0\(min):"
            }
            else{
                time = "\(min):"
            }
            if sec < 10 {
                time += "0\(sec)"
            }
            else{
                time += "\(sec)"
            }
            playTim.text = time
        }
    }
    //设置音乐图片
    func onSetImage(url:String){
        
        let image = self.imageCache[url] as? UIImage //从imageCache中获取图片
        if !image?{
            //如果缓存中没有 从网络中获取
            let imgUrl = NSURL(string: url)
            let request:NSURLRequest = NSURLRequest(URL: imgUrl)
            //异步获取
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {
                (response:NSURLResponse!,data:NSData!,error:NSError!) -> Void in
                let img = UIImage(data: data)
                self.iv.image = img
                self.imageCache[url] = img //将获取到的缩略图放入imageCache中
                
                })
        }
        else{
            self.iv.image = image
        }
        //self.iv.image = UIImage(named: "btnPlay.png")
    }
    func onChangedChannel(channel_id: String) {
        let url:String = "http://douban.fm/j/mine/playlist?channel=\(channel_id)"
        eHttp.onSearch(url)
        
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

