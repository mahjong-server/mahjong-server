CXX=g++

#EIGEN_LOCATION=$$HOME/local/eigen
#LBFGS_LOCATION=$$HOME/local/lbfgs

#BOOST_IO=/usr/lib/libboost_iostreams.so.1.42.0
#BOOST_LOCATION=/home/keii/lib/boost
BUILD_DIR=./objs

#CXXFLAGS+=-pg
CXXFLAGS =-Wall
#CXXFLAGS+=-g
#CXXFLAGS+=-p
CXXFLAGS+=-std=c++0x
CXXFLAGS+=-O3
#CXXFLAGS+=-g
#CXXFLAGS+=-O0

#CXXFLAGS+=-lm
#CXXFLAGS+=-fomit-frame-pointer
#CXXFLAGS+=-fno-schedule-insns2
#CXXFLAGS+=-fexceptions
#CXXFLAGS+=-funroll-loops
#CXXFLAGS+=-march=native
#CXXFLAGS+=-mfpmath=sse
#CXXFLAGS+=-msse
#CXXFLAGS+=-msse2
#CXXFLAGS+=-mssse3
#CXXFLAGS+=-msse4.1
#CXXFLAGS+=-msse4.2
#CXXFLAGS+=-mmmx
#CXXFLAGS+=-fopenmp
#CXXFLAGS+=-m64
#CXXFLAGS+=-DEIGEN_DONT_PARALLELIZE
#CXXFLAGS+=-DEIGEN_NO_DEBUG
#CXXFLAGS+=-DNDEBUG
#CXXFLAGS+=-DEIGEN_NO_STATIC_ASSERT
#CXXFLAGS+=-I$(EIGEN_LOCATION)
#CXXFLAGS+=-I$(LBFGS_LOCATION)/include
#CXXFLAGS+=-I$(BOOST_LOCATION)

#CXXLIBS =-lz $(BOOST_IO)
#CXXLIBS+=-pg
#CXXLIBS+=-fopenmp
#CXXLIBS+=-L$(LBFGS_LOCATION)/lib -llbfgs
#CXXLIBS+=-L$(BOOST_LOCATION)/libs

SRCS=$(shell ls *.cpp)
OBJS=$(SRCS:.cpp=.o)

PROGRAM=main

all : $(BUILD_DIR) $(patsubst %,$(BUILD_DIR)/%,$(PROGRAM))

$(BUILD_DIR)/%.o : %.cpp
	$(CXX) -c $(CXXFLAGS) -o $@ $<

$(BUILD_DIR)/$(PROGRAM) : $(patsubst %,$(BUILD_DIR)/%,$(OBJS))
	$(CXX) $(CXXFLAGS) $(CXXLIBS) -o $@ $^
	mv $(BUILD_DIR)/$(PROGRAM) ./
	rm -f ?*~

clean:
	rm -f $(BUILD_DIR)/* $(PROGRAM)
