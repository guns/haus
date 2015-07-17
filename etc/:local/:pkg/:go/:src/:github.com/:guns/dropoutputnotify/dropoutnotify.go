// Copyright (c) 2015 Sung Pae <self@sungpae.com>
// Distributed under the MIT license.
// http://www.opensource.org/licenses/mit-license.php

package main

import (
	"bufio"
	"html"
	"os"
	"os/exec"
	"strings"
	"time"
)

const (
	label    = "[DROPOUTPUT] "
	dstkey   = " DST="
	dptkey   = " DPT="
	protokey = " PROTO="

	pollduration = 1 * time.Second
)

func getvalue(s string, key string) string {
	if i := strings.Index(s, key); i > -1 {
		if j := strings.IndexByte(s[i+len(key):], ' '); j > -1 {
			return s[i+len(key) : i+len(key)+j]
		}
		return s[i+len(key):]
	}
	return ""
}

func putdropouts(s *bufio.Scanner, c chan string) {
	for s.Scan() {
		l := s.Text()
		if strings.Index(l, label) == -1 {
			continue
		}

		msg := getvalue(l, protokey) + " " + getvalue(l, dstkey) + ":" + getvalue(l, dptkey)

		select {
		case c <- msg:
		default:
			// Drop the message, the user is already alerted
		}
	}
}

func notifydropouts(c chan string) {
	for s := range c {
		cmd := exec.Command("notify-send", "[DROPOUTPUT]", html.EscapeString(s))
		if err := cmd.Run(); err != nil {
			println(err.Error())
		}
		time.Sleep(pollduration) // Rate limiting
	}
}

func main() {
	dmesg := exec.Command("dmesg", "--follow", "--raw", "--facility", "kern", "--level", "warn")
	stdout, err := dmesg.StdoutPipe()
	if err != nil {
		panic(err)
	}

	c := make(chan string)
	defer close(c)

	s := bufio.NewScanner(stdout)
	dmesg.Start()

	go putdropouts(s, c)
	time.Sleep(1 * time.Second) // A moment to drain the dmesg buffer
	go notifydropouts(c)

	// Always terminate the process in case of panic
	defer dmesg.Process.Signal(os.Interrupt)
	dmesg.Wait()
}
