#ifndef NETWORKQUEUE_H
#define NETWORKQUEUE_H

#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>

// Class is a queue but extended for use
// with our Network making use of a mutex.
template <typename T>
class NetworkQueue
{
    public:

        // Return the value on the top of the queue, popping in the process.
        T pop()
        {
            std::unique_lock<std::mutex> mlock(_mutex);
            while(_queue.empty())
                _cond.wait(mlock);

            auto val = _queue.front();
            _queue.pop();
            return val;
        }

        // Sets the referenced item to the equal the front of the queue,
        // popping in the process.
        void pop(T& item)
        {
            std::unique_lock<std::mutex> mlock(_mutex);
            while(_queue.empty())
                _cond.wait(mlock);

            item = _queue.front();
            _queue.pop();
        }

        // Wait until "item" is in queue then pop it
        T wait_pop(T& item)
        {
          std::unique_lock<std::mutex> mlock(_mutex);
          _cond.wait(mlock, [this]{return !_queue.empty();});
          item = _queue.front();
          _queue.pop();
          return item;
        }

        // See if item is in queue
        bool try_pop(T& item)
        {
            std::unique_lock<std::mutex> mlock(_mutex);
            if(_queue.empty())
                return false;

            item = _queue.front();
            _queue.pop();
            return true;
        }

        // Add an item to the back of the queue
        void push(const T& item)
        {
            std::unique_lock<std::mutex> mlock(_mutex);
            _queue.push(item);
            mlock.unlock();
            _cond.notify_one();
        }

        NetworkQueue() = default;
        NetworkQueue(const NetworkQueue&) = delete; // disable copying
        NetworkQueue& operator = (const NetworkQueue&) = delete; // disable assign

        inline int getSize() const { return _queue.size(); }

    private:

        std::queue<T> _queue;
        std::mutex _mutex;
        std::condition_variable _cond;
};

#endif // NETWORKQUEUE_H
