// Written in the D programming language.

/**
 * Interface to C++ <typeinfo>
 *
 * Copyright: Copyright (c) 2016 D Language Foundation
 * License:   $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors:   $(HTTP digitalmars.com, Walter Bright)
 * Source:    $(DRUNTIMESRC core/stdcpp/_typeinfo.d)
 */

module core.experimental.stdcpp.typeinfo;

version (CppRuntime_DigitalMars)
{
    import core.experimental.stdcpp.exception;

    extern (C++, "std"):

    class type_info
    {
        void* pdata;

    public:
        //virtual ~this();
        void dtor() { }     // reserve slot in vtbl[]

        //bool operator==(const type_info rhs) const;
        //bool operator!=(const type_info rhs) const;
        final bool before(const type_info rhs) const;
        final const(char)* name() const;
    protected:
        //type_info();
    private:
        //this(const type_info rhs);
        //type_info operator=(const type_info rhs);
    }

    class bad_cast : exception
    {
        this() nothrow { }
        this(const bad_cast) nothrow { }
        //bad_cast operator=(const bad_cast) nothrow { return this; }
        //virtual ~this() nothrow;
        override const(char)* what() const nothrow;
    }

    class bad_typeid : exception
    {
        this() nothrow { }
        this(const bad_typeid) nothrow { }
        //bad_typeid operator=(const bad_typeid) nothrow { return this; }
        //virtual ~this() nothrow;
        override const (char)* what() const nothrow;
    }
}
else version (CppRuntime_Microsoft)
{
    import core.experimental.stdcpp.exception;

    extern (C++, "std"):

    struct __type_info_node
    {
        void* _MemPtr;
        __type_info_node* _Next;
    }

    extern __gshared __type_info_node __type_info_root_node;

    class type_info
    {
        //virtual ~this();
        void dtor() { }     // reserve slot in vtbl[]
        //bool operator==(const type_info rhs) const;
        //bool operator!=(const type_info rhs) const;
        final bool before(const type_info rhs) const;
        final const(char)* name(__type_info_node* p = &__type_info_root_node) const;

    private:
        void* pdata;
        char[1] _name;
        //type_info operator=(const type_info rhs);
    }

    class bad_cast : exception
    {
        this(const(char)* msg = "bad cast");
        //virtual ~this();
    }

    class bad_typeid : exception
    {
        this(const(char)* msg = "bad typeid");
        //virtual ~this();
    }
}
else version (CppRuntime_Gcc)
{
    import core.experimental.stdcpp.exception;

    extern (C++, "__cxxabiv1")
    {
        class __class_type_info {}
    }

    extern (C++, "std"):

    class type_info
    {
        ~this();
        final const(char)* name()() const nothrow {
            return _name[0] == '*' ? _name + 1 : _name;
        }
        final bool before()(const type_info _arg) const {
            import core.stdc.string : strcmp;
            return (_name[0] == '*' && _arg._name[0] == '*')
                ? _name < _arg._name
                : strcmp(_name, _arg._name) < 0;
        }
        //bool operator==(const type_info) const;
        bool __is_pointer_p() const;
        bool __is_function_p() const;
        bool __do_catch(const type_info, void**, uint) const;
        bool __do_upcast(const __class_type_info, void**) const;

        const(char)* _name;
        this(const(char)*);
    }

    class bad_cast : exception
    {
        this() {}
        //~this();
        override const(char)* what() const;
    }

    class bad_typeid : exception
    {
        this() {}
        //~this();
        override const(char)* what() const;
    }
}
else version (CppRuntime_Clang)
{
    import core.experimental.stdcpp.exception;

    version (iOS) version (D_LP64)
        version = iOS64;

    version (iOS64)
        enum _LIBCPP_NONUNIQUE_RTTI_BIT = 1UL << 63;
    else
        enum _LIBCPP_NONUNIQUE_RTTI_BIT = 0;

    static if (_LIBCPP_NONUNIQUE_RTTI_BIT)
        version = _LIBCPP_HAS_NONUNIQUE_TYPEINFO;
    else
        version = _LIBCPP_HAS_UNIQUE_TYPEINFO;

    extern (C++, "std"):

    class type_info
    {
        ~this();
        //final bool operator==(const type_info rhs) const;
        //final bool operator!=(const type_info rhs) const;

        version (_LIBCPP_HAS_NONUNIQUE_TYPEINFO)
        {
            import core.stdc.stdint : uintptr_t;

            final int __compare_nonunique_names(const type_info __arg) const
            {
                import core.stdc.string : strcmp;
                return strcmp(name(), __arg.name());
            }

            final const(char)* name() const
            {
                return cast(const(char)*) (__type_name & ~_LIBCPP_NONUNIQUE_RTTI_BIT);
            }

            final bool before(const type_info __arg) const
            {
                if (!((__type_name & __arg.__type_name) & _LIBCPP_NONUNIQUE_RTTI_BIT))
                    return __type_name < __arg.__type_name;
                return __compare_nonunique_names(__arg) < 0;
            }

            final size_t hash_code() const
            {
                if (!(__type_name & _LIBCPP_NONUNIQUE_RTTI_BIT))
                    return __type_name;

                const(char)* __ptr = name();
                size_t __hash = 5381;
                ubyte __c;
                while ((__c = cast(ubyte)(*__ptr++)) != 0)
                    __hash = (__hash * 33) ^ __c;
                return __hash;
            }

            //bool operator==(const type_info& __arg) const

            uintptr_t __type_name;
            this(const(char)* __n) { __type_name = cast(uintptr_t) __n; }
        }
        else
        {
            final const(char)* name() const { return __type_name; }
            final bool before(const type_info __arg) const { return __type_name < __arg.__type_name; }
            final size_t hash_code() const { return cast(size_t) __type_name; }
            //bool operator==(const type_info& __arg) const

            const(char)* __type_name;
            this(const(char)* __n) { __type_name = __n; }
        }

        //bool operator!=(const type_info& __arg) const
    }

    class bad_cast : exception
    {
        this();
        ~this();
        override const(char)* what() const;
    }

    class bad_typeid : exception
    {
        this();
        ~this();
        override const(char)* what() const;
    }
}
else
    static assert(0, "Missing std::type_info binding for this platform");
