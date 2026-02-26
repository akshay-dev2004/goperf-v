package stats

import (
	"time"

	hdrhistogram "github.com/HdrHistogram/hdrhistogram-go"
)

type HistogramRecorder struct {
	histogram *hdrhistogram.Histogram
}

func NewHistogramRecorder(timeout time.Duration) *HistogramRecorder {
	return &HistogramRecorder{
		histogram: hdrhistogram.New(1000, timeout.Nanoseconds(), 3),
	}
}
