package main

import (
	"flag"
	"fmt"
	human "github.com/dustin/go-humanize"
	"syscall"
	"unsafe"
)

var MAX = flag.Uint64("max", 35000, "-max=2048 value is in MB")
var MIN = flag.Uint64("min", 10, "-min=10 value is in MB")
var PID = flag.Uint64("pid", 0, "-pid=200 value is the process id of the application you want to adjust")

const (
	FILE_CACHE_MAX_HARD_ENABLE     = 0x1
	FILE_CACHE_MIN_HARD_ENABLE     = 0x4
	QUOTA_LIMITS_HARDWS_MAX_ENABLE = 0x00000004
	PROCESS_ALL_ACCESS             = 0x1F0FFF
)

func abort(funcname string, err error) {
	panic(fmt.Sprintf("%s failed: %v", funcname, err))
}

func SetProcessWorkingSizeEX() {
	kernel32, err := syscall.LoadDLL("kernel32.dll")
	if nil != err {
		abort("loadLibrary", err)
	}
	defer kernel32.Release()
	set, err := kernel32.FindProc("SetProcessWorkingSetSizeEx")
	if nil != err {
		abort("SetProcessWorkingSetSizeEx", err)
	}
	proc, err := kernel32.FindProc("OpenProcess")
	if nil != err {
		abort("OpenProcess", err)
	}
	ph, _, err := proc.Call(uintptr(PROCESS_ALL_ACCESS), uintptr(0), uintptr(*PID))
	if "The operation completed successfully." != err.Error() {
		abort("OpenProcess", err)
	}
	var lpFlags uint32
	lpFlags = QUOTA_LIMITS_HARDWS_MAX_ENABLE
	max := *MAX * uint64(1000) * uint64(1000)
	min := *MIN * uint64(1000) * uint64(1000)
	res, _, err := set.Call(uintptr(ph), uintptr(min), uintptr(max), uintptr(lpFlags))
	if res == 0 {
		abort("SetProcessWorkingSetSizeEx", err)
	}
}

func GetProcessWorkSizeEx() string {
	kernel32, err := syscall.LoadDLL("kernel32.dll")
	if nil != err {
		abort("loadLibrary", err)
	}
	defer kernel32.Release()
	get, err := kernel32.FindProc("GetProcessWorkingSetSizeEx")
	if nil != err {
		abort("SetProcessWorkingSetSizeEx", err)
	}
	proc, err := kernel32.FindProc("OpenProcess")
	if nil != err {
		abort("OpenProcess", err)
	}
	ph, _, err := proc.Call(uintptr(PROCESS_ALL_ACCESS), uintptr(0), uintptr(*PID))
	if "The operation completed successfully." != err.Error() {
		abort("OpenProcess", err)
	}
	var lpFlags uint32
	lpFlags = QUOTA_LIMITS_HARDWS_MAX_ENABLE
	max := uint64(0)
	min := uint64(0)
	res, _, err := get.Call(uintptr(ph), uintptr(unsafe.Pointer(&min)), uintptr(unsafe.Pointer(&max)), uintptr(unsafe.Pointer(&lpFlags)))
	if res == 0 {
		abort("SetProcessWorkingSetSizeEx", err)
	}

	return fmt.Sprintf("min: %v max:%v flags:%v", human.Bytes(min), human.Bytes(max), lpFlags)
}

func main() {
	flag.Parse()
	fmt.Println("Before: ", GetProcessWorkSizeEx())
	SetProcessWorkingSizeEX()
	fmt.Println("After: ", GetProcessWorkSizeEx())
}
