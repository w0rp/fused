module fuse.fuse_common;

import core.stdc.config;
import std.bitmanip: bitfields;

import fuse.fuse_opt;

/** Major version of FUSE library interface */
enum FUSE_MAJOR_VERSION = 2;

/** Minor version of FUSE library interface */
enum FUSE_MINOR_VERSION = 9;

enum FUSE_VERSION = FUSE_MAJOR_VERSION * 10 + FUSE_MINOR_VERSION; 

/// FUSE uses a 64-bit signed off_t
alias fuse_off_t = long;

/**
 * Information about open files
 *
 * Changed in version 2.5
 */
struct fuse_file_info {
    /** Open flags.  Available in open() and release() */
    int flags;
    
    /** Old file handle, don't use */
    deprecated c_ulong fh_old;
    
    /** In case of a write operation indicates if this was caused by a
        writepage */
    int writepage;

    mixin(bitfields!(
        /** Can be filled in by open, to use direct I/O on this file.
            Introduced in version 2.4 */
        uint, "direct_io", 1,
        /** Can be filled in by open, to indicate, that cached file data
            need not be invalidated.  Introduced in version 2.4 */
        uint, "keep_cache", 1,
        /** Indicates a flush operation.  Set in flush operation, also
            maybe set in highlevel lock operation and lowlevel release
            operation.  Introduced in version 2.6 */
        uint, "flush", 1,
        /** Can be filled in by open, to indicate that the file is not
            seekable.  Introduced in version 2.8 */
        uint, "nonseekable", 1,
        /* Indicates that flock locks for this file should be
           released.  If set, lock_owner shall contain a valid value.
           May only be set in ->release().  Introduced in version
           2.9 */
        uint, "flock_release", 1,
        /** Padding.  Do not use*/
        uint, "padding", 27,
    ));

    /** File handle.  May be filled in by filesystem in open().
        Available in all other file operations */
    ulong fh;

    /** Lock owner id.  Available in locking operations and flush */
    ulong lock_owner;
};

// Capability bits for 'fuse_conn_info.capable' and 'fuse_conn_info.want'

/// filesystem supports asynchronous read requests
enum FUSE_CAP_ASYNC_READ = (1 << 0);
/// filesystem supports "remote" locking
enum FUSE_CAP_POSIX_LOCKS = (1 << 1);
/// filesystem handles the O_TRUNC open flag
enum FUSE_CAP_ATOMIC_O_TRUNC = (1 << 3);
/// filesystem handles lookups of "." and ".."
enum FUSE_CAP_EXPORT_SUPPORT = (1 << 4);
/// filesystem can handle write size larger than 4kB
enum FUSE_CAP_BIG_WRITES = (1 << 5);
/// don't apply umask to file mode on create operations
enum FUSE_CAP_DONT_MASK = (1 << 6);
/// ability to use splice() to write to the fuse device
enum FUSE_CAP_SPLICE_WRITE = (1 << 7);
/// ability to move data to the fuse device with splice()
enum FUSE_CAP_SPLICE_MOVE = (1 << 8);
/// ability to use splice() to read from the fuse device
enum FUSE_CAP_SPLICE_READ = (1 << 9);

enum FUSE_CAP_FLOCK_LOCKS = (1 << 10);
/// ioctl support on directories
enum FUSE_CAP_IOCTL_DIR = (1 << 11);

// Ioctl flags

/// 32bit compat ioctl on 64bit machine
enum FUSE_IOCTL_COMPAT = (1 << 0);
/// not restricted to well-formed ioctls, retry allowed
enum FUSE_IOCTL_UNRESTRICTED = (1 << 1);
/// retry with new iovecs
enum FUSE_IOCTL_RETRY = (1 << 2);
/// is a directory
enum FUSE_IOCTL_DIR = (1 << 4);

/// maximum of in_iovecs + out_iovecs
enum FUSE_IOCTL_MAX_IOV = 256;

/**
 * Connection information, passed to the ->init() method
 *
 * Some of the elements are read-write, these can be changed to
 * indicate the value requested by the filesystem.  The requested
 * value must usually be smaller than the indicated value.
 */
struct fuse_conn_info {
    /**
     * Major version of the protocol (read-only)
     */
    uint proto_major;
    
    /**
     * Minor version of the protocol (read-only)
     */
    uint proto_minor;
    
    /**
     * Is asynchronous read supported (read-write)
     */
    uint async_read;
    
    /**
     * Maximum size of the write buffer
     */
    uint max_write;
    
    /**
     * Maximum readahead
     */
    uint max_readahead;
    
    /**
     * Capability flags, that the kernel supports
     */
    uint capable;
    
    /**
     * Capability flags, that the filesystem wants to enable
     */
    uint want;
    
    /**
     * Maximum number of backgrounded requests
     */
    uint max_background;
    
    /**
     * Kernel congestion threshold parameter
     */
    uint congestion_threshold;
    
    /**
     * For future use.
     */
    uint[23] reserved;
};

struct fuse_session;
struct fuse_chan;
struct fuse_pollhandle;

/**
 * Create a FUSE mountpoint
 *
 * Returns a control file descriptor suitable for passing to
 * fuse_new()
 *
 * Params:
 * mountpoint = the mount point path
 * args = argument vector
 * 
 * Returns: the communication channel on success, NULL on failure
 */
extern(C) nothrow fuse_chan* fuse_mount(const(char)* mountpoint, fuse_args* args);

/**
 * Umount a FUSE mountpoint
 *
 * Params:
 * mountpoint = the mount point path
 * ch = the communication channel
 */
extern(C) nothrow void fuse_unmount(const(char)* mountpoint, fuse_chan* ch);

/**
 * Parse common options
 *
 * The following options are parsed:
 *
 *   '-f'        foreground
 *   '-d' '-odebug'  foreground, but keep the debug option
 *   '-s'        single threaded
 *   '-h' '--help'   help
 *   '-ho'       help without header
 *   '-ofsname=..'   file system name, if not present, then set to the program
 *           name
 *
 * All parameters may be NULL
 *
 * Params:
 * args = argument vector
 * mountpoint = the returned mountpoint, should be freed after use
 * multithreaded = set to 1 unless the '-s' option is present
 * foreground = set to 1 if one of the relevant options is present
 *
 * Returns: 0 on success, -1 on failure
 */
extern(C) nothrow int fuse_parse_cmdline
(fuse_args* args, char** mountpoint, int* multithreaded, int* foreground);

/**
 * Go into the background
 *
 * Params:
 * foreground = if true, stay in the foreground
 *
 * Returns: 0 on success, -1 on failure
 */
extern(C) nothrow int fuse_daemonize(int foreground);

/**
 * Get the version of the library
 *
 * Returns: the version
 */
extern(C) nothrow int fuse_version();

/**
 * Destroy poll handle
 *
 * Params:
 * ph = the poll handle
 */
extern(C) nothrow void fuse_pollhandle_destroy(fuse_pollhandle* ph);

/**
 * Buffer flags
 */
enum fuse_buf_flags {
    /**
     * Buffer contains a file descriptor
     *
     * If this flag is set, the .fd field is valid, otherwise the
     * .mem fields is valid.
     */
    FUSE_BUF_IS_FD = (1 << 1),
    
    /**
     * Seek on the file descriptor
     *
     * If this flag is set then the .pos field is valid and is
     * used to seek to the given offset before performing
     * operation on file descriptor.
     */
    FUSE_BUF_FD_SEEK = (1 << 2),
    
    /**
     * Retry operation on file descriptor
     *
     * If this flag is set then retry operation on file descriptor
     * until .size bytes have been copied or an error or EOF is
     * detected.
     */
    FUSE_BUF_FD_RETRY = (1 << 3),
};


/**
 * Buffer copy flags
 */
enum fuse_buf_copy_flags {
    /**
     * Don't use splice(2)
     *
     * Always fall back to using read and write instead of
     * splice(2) to copy data from one file descriptor to another.
     *
     * If this flag is not set, then only fall back if splice is
     * unavailable.
     */
    FUSE_BUF_NO_SPLICE = (1 << 1),
    
    /**
     * Force splice
     *
     * Always use splice(2) to copy data from one file descriptor
     * to another.  If splice is not available, return -EINVAL.
     */
    FUSE_BUF_FORCE_SPLICE = (1 << 2),
    
    /**
     * Try to move data with splice.
     *
     * If splice is used, try to move pages from the source to the
     * destination instead of copying.  See documentation of
     * SPLICE_F_MOVE in splice(2) man page.
     */
    FUSE_BUF_SPLICE_MOVE = (1 << 3),
    
    /**
     * Don't block on the pipe when copying data with splice
     *
     * Makes the operations on the pipe non-blocking (if the pipe
     * is full or empty).  See SPLICE_F_NONBLOCK in the splice(2)
     * man page.
     */
    FUSE_BUF_SPLICE_NONBLOCK = (1 << 4),
};

/**
 * Single data buffer
 *
 * Generic data buffer for I/O, extended attributes, etc...  Data may
 * be supplied as a memory pointer or as a file descriptor
 */
struct fuse_buf {
    /**
     * Size of data in bytes
     */
    size_t size;
    
    /**
     * Buffer flags
     */
    fuse_buf_flags flags;
    
    /**
     * Memory pointer
     *
     * Used unless FUSE_BUF_IS_FD flag is set.
     */
    void *mem;
    
    /**
     * File descriptor
     *
     * Used if FUSE_BUF_IS_FD flag is set.
     */
    int fd;
    
    /**
     * File position
     *
     * Used if FUSE_BUF_FD_SEEK flag is set.
     */
    fuse_off_t pos;
};

/**
 * Data buffer vector
 *
 * An array of data buffers, each containing a memory pointer or a
 * file descriptor.
 *
 * Allocate dynamically to add more than one buffer.
 */
struct fuse_bufvec {
    /**
     * Number of buffers in the array
     */
    size_t count;
    
    /**
     * Index of current buffer within the array
     */
    size_t idx;
    
    /**
     * Current offset within the current buffer
     */
    size_t off;
    
    /**
     * Array of buffers
     */
    fuse_buf[1] buf;
};

// This was translated from a C macro to a D function.
/* Initialize bufvec with a single buffer of given size */
@safe pure nothrow
fuse_bufvec FUSE_BUFVEC_INIT(size_t size) {
    fuse_buf buf = {
        size: size,
        flags: cast(fuse_buf_flags) 0,
        mem: null,
        fd: -1,
        pos: 0,
    };
    
    fuse_bufvec vec;
    
    vec.count = 1;
    vec.idx = 0;
    vec.off = 0;
    vec.buf = [buf];
    
    return vec;
}

/**
 * Get total size of data in a fuse buffer vector
 *
 * Params:
 * bufv = buffer vector
 *
 * Returns: size of data
 */
extern(C) nothrow size_t fuse_buf_size(const(fuse_bufvec)* bufv);


/**
 * Copy data from one buffer vector to another
 *
 * @param dst destination buffer vector
 * @param src source buffer vector
 * @param flags flags controlling the copy
 * @return actual number of bytes copied or -errno on error
 */
extern(C) nothrow ptrdiff_t fuse_buf_copy
(fuse_bufvec* dst, fuse_bufvec* src, fuse_buf_copy_flags flags);

/**
 * Exit session on HUP, TERM and INT signals and ignore PIPE signal
 *
 * Stores session in a global variable.  May only be called once per
 * process until fuse_remove_signal_handlers() is called.
 *
 * Params:
 * se = the session to exit
 * 
 * Returns: 0 on success, -1 on failure
 */
extern(C) nothrow int fuse_set_signal_handlers(fuse_session* se);

/**
 * Restore default signal handlers
 *
 * Resets global session.  After this fuse_set_signal_handlers() may
 * be called again.
 *
 * Params:
 * se = the same session as given in fuse_set_signal_handlers()
 */
extern(C) nothrow void fuse_remove_signal_handlers(fuse_session* se);

/**
 * Restore default signal handlers
 *
 * Resets global session.  After this fuse_set_signal_handlers() may
 * be called again.
 *
 * Params:
 * se = the same session as given in fuse_set_signal_handlers()
 */
extern(C) nothrow void fuse_remove_signal_handlers(fuse_session* se);

/*
This wasn't translated from the header file. Maybe it'll matter later.

#if FUSE_USE_VERSION < 26
#    ifdef __FreeBSD__
#    if FUSE_USE_VERSION < 25
#        error On FreeBSD API version 25 or greater must be used
#    endif
#    endif
#    include "fuse_common_compat.h"
#    undef FUSE_MINOR_VERSION
#    undef fuse_main
#    define fuse_unmount fuse_unmount_compat22
#    if FUSE_USE_VERSION == 25
#    define FUSE_MINOR_VERSION 5
#    define fuse_mount fuse_mount_compat25
#    elif FUSE_USE_VERSION == 24 || FUSE_USE_VERSION == 22
#    define FUSE_MINOR_VERSION 4
#    define fuse_mount fuse_mount_compat22
#    elif FUSE_USE_VERSION == 21
#    define FUSE_MINOR_VERSION 1
#    define fuse_mount fuse_mount_compat22
#    elif FUSE_USE_VERSION == 11
#    warning Compatibility with API version 11 is deprecated
#    undef FUSE_MAJOR_VERSION
#    define FUSE_MAJOR_VERSION 1
#    define FUSE_MINOR_VERSION 1
#    define fuse_mount fuse_mount_compat1
#    else
#    error Compatibility with API version other than 21, 22, 24, 25 and 11 not supported
#    endif
#endif
*/
