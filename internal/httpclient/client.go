package httpclient

import (
	"context"
	"errors"
	"net"
	"net/http"
	"strings"
	"time"
)

type RequestResult struct {
	StatusCode int
	Duration   time.Duration
	Error      error
}

var client = &http.Client{
	Timeout: 10 * time.Second,
}

func MakeRequest(ctx context.Context,url string) (statusCode int, duration time.Duration, err error) {

	start := time.Now()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return 0, 0, err
	}

	resp, err := client.Do(req)
	duration = time.Since(start)

	if err != nil {

		var netErr *net.OpError

		if errors.As(err, &netErr) {

			if netErr.Op == "dial" {
				if strings.Contains(netErr.Err.Error(), "refused") {
					return 0, duration, errors.New("connection refused")
				}
				if strings.Contains(netErr.Err.Error(), "no such host") {
					return 0, duration, errors.New("no such host")
				}
			}
		}

		return 0, duration, err
	}

	defer resp.Body.Close()

	return resp.StatusCode, duration, nil
}

func RunMultiple(ctx context.Context, url string, n int) []RequestResult {
	results := make([]RequestResult, n)
	for i := 0; i < n; i++ {
		statusCode, duration, err := MakeRequest(ctx,url)
		results[i] = RequestResult{
			StatusCode: statusCode,
			Duration:   duration,
			Error:      err,
		}
	}
	return results
}
