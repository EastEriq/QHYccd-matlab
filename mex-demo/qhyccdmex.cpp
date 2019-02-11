#include "qhyccd.h"
#include "mex.h"
#include <time.h>
#include <string.h>
#ifdef WIN32
  #include <windows.h>
#else
  #include <unistd.h>
#endif

void
mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
{
    int num = 0;
    qhyccd_handle *camhandle = NULL;
    int ret = QHYCCD_ERROR;
    char id[32];
    int found = 0;
    unsigned int w,h,bpp,channels;
    unsigned char *ImgData;
    int camtime = 200,camgain = 30,camoffset = 0,camspeed = 0,cambinx = 1,cambiny = 1;
	
	int cambits = 8,camusbtraffic = 30;


	ret = InitQHYCCDResource();
    if(ret == QHYCCD_SUCCESS)
    {
        printf("Init SDK success!\n");
    }
    else
    {
        printf("Init SDK failed!\n");
    }

    num = ScanQHYCCD();
    if(num > 0)
    {
        printf("Yes!Found QHYCCD,the num is %d \n",num);
    }
    else
    {
        printf("Not Found QHYCCD,please check the usblink or the power\n");
    }

    for(int i = 0;i < num;i++)
    {
        ret = GetQHYCCDId(i,id);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("connected to the first camera from the list,id is %s\n",id);
            found = 1;
            break;
        }
    }

    if(found == 1)
    { 
        camhandle = OpenQHYCCD(id);
        if(camhandle != NULL)
        {
            printf("Open QHYCCD success!\n");
        }
        else
        {
            printf("Open QHYCCD fail \n");
        }

        ret = SetQHYCCDStreamMode(camhandle,0);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("SetQHYCCDStreamMode success!\n");
        }
        else
        {
            printf("SetQHYCCDStreamMode code:%d\n",ret);
        }

        ret = InitQHYCCD(camhandle);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("Init QHYCCD success!\n");
        }
        else
        {
            printf("Init QHYCCD fail code:%d\n",ret);
        }
     
        double chipw,chiph,pixelw,pixelh;
        ret = GetQHYCCDChipInfo(camhandle,&chipw,&chiph,&w,&h,&pixelw,&pixelh,&bpp);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("GetQHYCCDChipInfo success!\n");
            printf("CCD/CMOS chip information:\n");
            printf("Chip width %3f mm,Chip height %3f mm\n",chipw,chiph);
            printf("Chip pixel width %3f um,Chip pixel height %3f um\n",pixelw,pixelh);
            printf("Chip Max Resolution is %d x %d,depth is %d\n",w,h,bpp);
        }
        else
        {
            printf("GetQHYCCDChipInfo fail\n");
        }
         

        ret = IsQHYCCDControlAvailable(camhandle,CONTROL_USBTRAFFIC);
        if(ret == QHYCCD_SUCCESS)
        {
            ret = SetQHYCCDParam(camhandle,CONTROL_USBTRAFFIC,camusbtraffic);
            if(ret != QHYCCD_SUCCESS)
            {
                printf("SetQHYCCDParam CONTROL_USBTRAFFIC failed\n");
            }
        }

        ret = IsQHYCCDControlAvailable(camhandle,CONTROL_GAIN);
        if(ret == QHYCCD_SUCCESS)
        {
            ret = SetQHYCCDParam(camhandle,CONTROL_GAIN,camgain);
            if(ret != QHYCCD_SUCCESS)
            {
                printf("SetQHYCCDParam CONTROL_GAIN failed\n");
            }
        }

        ret = IsQHYCCDControlAvailable(camhandle,CONTROL_OFFSET);
        if(ret == QHYCCD_SUCCESS)
        {
            ret = SetQHYCCDParam(camhandle,CONTROL_OFFSET,camoffset);
            if(ret != QHYCCD_SUCCESS)
            {
                printf("SetQHYCCDParam CONTROL_GAIN failed\n");
            }
        }

        ret = SetQHYCCDParam(camhandle,CONTROL_EXPOSURE,camtime);
        if(ret != QHYCCD_SUCCESS)
        {
            printf("SetQHYCCDParam CONTROL_EXPOSURE failed\n");
        }        

        ret = SetQHYCCDResolution(camhandle,0,0,w,h);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("SetQHYCCDResolution success!\n");
        }
        else
        {
            printf("SetQHYCCDResolution fail\n");
        }
        
        ret = SetQHYCCDBinMode(camhandle,cambinx,cambiny);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("SetQHYCCDBinMode success!\n");
        }
        else
        {
            printf("SetQHYCCDBinMode fail\n");
        } 

        ret = SetQHYCCDBitsMode(camhandle,cambits);
        if(ret != QHYCCD_SUCCESS)
        {
           printf("SetQHYCCDParam CONTROL_GAIN failed\n");
        }

        ret = ExpQHYCCDSingleFrame(camhandle);
        if( ret != QHYCCD_ERROR )
        {
            printf("ExpQHYCCDSingleFrame success!\n");
            if( ret != QHYCCD_READ_DIRECTLY )
            {
#ifdef WIN32
                Sleep(100);
#else
                sleep(0.1);
#endif
            } 
        }
        else
        {
            printf("ExpQHYCCDSingleFrame fail\n"); 
        }
        
        uint32_t length = GetQHYCCDMemLength(camhandle);
        
        if(length > 0) 
        {
            ImgData = (unsigned char *)malloc(length*2); 
            memset(ImgData,0,length*2);
        }
        else
        {
            printf("Get the min memory space length failure \n");
        }

        ret = GetQHYCCDSingleFrame(camhandle,&w,&h,&bpp,&channels,ImgData);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("GetQHYCCDSingleFrame succeess! bpp=%d\n",bpp);
            //to do anything you like:
			if(8 == bpp)
			{
                plhs[0] = mxCreateNumericMatrix(w,h,mxUINT8_CLASS,mxREAL);
				uint8_t * pImage = (uint8_t*)mxGetData(plhs[0]);
				memcpy(pImage,ImgData,w*h); 
			}
			else
			{
				plhs[0] = mxCreateNumericMatrix(w,h,mxUINT16_CLASS,mxREAL);
				uint16_t * pImage = (uint16_t*)mxGetData(plhs[0]);
				memcpy(pImage,ImgData,w*h*2); 
			}
        }
        else 
        {
            printf("GetQHYCCDSingleFrame fail:%d\n",ret);
        }
 
        delete(ImgData);  
    }
    else
    {
        printf("The camera is not QHYCCD or other error \n");
    }

    if(camhandle) 
    {
       ret =   CancelQHYCCDExposing(camhandle);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("CancelQHYCCDExposingAndReadout success!\n");
        }
        else
        {
            printf("CancelQHYCCDExposingAndReadout failed\n");
        }
        
        ret = CloseQHYCCD(camhandle);
        if(ret == QHYCCD_SUCCESS)
        {
            printf("Close QHYCCD success!\n");
        }
        else
        {
            printf("Close QHYCCD failed!\n");
        }
    }
  
    ret = ReleaseQHYCCDResource();
    if(ret == QHYCCD_SUCCESS)
    {
        printf("Rlease SDK Resource  success!\n");
    }
    else
    {
        printf("Rlease SDK Resource  failed!\n");
    }
}
