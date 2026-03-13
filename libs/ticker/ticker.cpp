#include "ticker.h"
#include "cxx14_smoke.h"

#include <cinttypes>
#include <cstdio>
#include <cstdint>

#if defined(HAVE_XENOMAI) && HAVE_XENOMAI

  #include <native/task.h>

  namespace {
    void ticker_task(void* arg) {
      auto period_ms = *static_cast<std::uint32_t*>(arg);

      std::printf("[Xenomai] smoke=%s\n", ticker::cxx14_smoke().c_str());
      std::fflush(stdout);

      const RTIME period_ns = static_cast<RTIME>(period_ms) * 1000 * 1000;

      for (std::uint64_t i = 0;; ++i) {
        std::printf("[Xenomai] tick=%" PRIu64 "\n", i);
        std::fflush(stdout);
        rt_task_sleep(period_ns);
      }
    }
  }

  namespace ticker {
    void run(std::uint32_t period_ms) {
      RT_TASK task;

      int rc = rt_task_create(&task, "ticker", 0, 80, 0);
      if (rc) {
        std::printf("[Xenomai] rt_task_create failed: %d\n", rc);
        return;
      }

      rc = rt_task_start(&task, &ticker_task, &period_ms);
      if (rc) {
        std::printf("[Xenomai] rt_task_start failed: %d\n", rc);
        return;
      }

      // Keep process alive
      for (;;) {
        rt_task_sleep(1000 * 1000 * 1000);
      }
    }
  }

#elif defined(HAVE_POSIX_TICKER) && HAVE_POSIX_TICKER

  #include <cerrno>
  #include <cstring>
  #include <time.h>

  static timespec add_ns(timespec t, long long ns) {
    constexpr long long NSEC = 1000LL * 1000LL * 1000LL;
    t.tv_nsec += static_cast<long>(ns % NSEC);
    t.tv_sec  += static_cast<time_t>(ns / NSEC);
    if (t.tv_nsec >= NSEC) { t.tv_nsec -= NSEC; t.tv_sec += 1; }
    return t;
  }

  namespace ticker {
    void run(std::uint32_t period_ms) {
      std::printf("[POSIX] smoke=%s\n", cxx14_smoke().c_str());
      std::printf("[POSIX] ticker started, period=%" PRIu32 "ms\n", period_ms);
      std::fflush(stdout);

      const long long period_ns = static_cast<long long>(period_ms) * 1000LL * 1000LL;

      timespec next{};
      clock_gettime(CLOCK_MONOTONIC, &next);
      next = add_ns(next, period_ns);

      for (std::uint64_t i = 0;; ++i) {
        int rc = clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &next, nullptr);
        if (rc != 0) {
          std::printf("[POSIX] clock_nanosleep failed: %s\n", std::strerror(rc));
          break;
        }
        std::printf("[POSIX] tick=%" PRIu64 "\n", i);
        std::fflush(stdout);
        next = add_ns(next, period_ns);
      }
    }
  }

#else

  #include <chrono>
  #include <iostream>
  #include <thread>

  namespace ticker {
    void run(std::uint32_t period_ms) {
      std::cout << "[Portable] smoke=" << cxx14_smoke() << "\n";
      std::cout << "[Portable] ticker started, period=" << period_ms << "ms\n";
      std::uint64_t i = 0;
      for (;;) {
        std::cout << "[Portable] tick=" << i++ << "\n";
        std::this_thread::sleep_for(std::chrono::milliseconds(period_ms));
      }
    }
  }

#endif
