// Copyright (c) 2015 Sung Pae <self@sungpae.com>
// Distributed under the MIT license.
// http://www.opensource.org/licenses/mit-license.php

package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestGetvalue(t *testing.T) {
	l := "[DROPOUTPUT] DST=127.0.0.1 DPT=8080"
	assert.Equal(t, "127.0.0.1", getvalue(l, " DST="))
	assert.Equal(t, "8080", getvalue(l, " DPT="))
}
