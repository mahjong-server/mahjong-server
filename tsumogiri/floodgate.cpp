#include "easywsclient.hpp"
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
//#include <string.h>
#include <fstream>
#include "picojson.h"
#include "fstream"
#include <vector>
#include <iostream>
#include <sstream>


using namespace std;
using namespace picojson;

int player_number=0;
string rec_message="";
string ParseToGame(const char *buf)
{
  value v;
  
  picojson::parse(v,buf,buf+strlen(buf));
  picojson::object& o = v.get<picojson::object>();
  picojson::object send;
  //cout<<o["type"].get<string>()<<endl;
  
  if(o["type"].get<string>()=="hello")
    { 
      send["type"]=(picojson::value)string("join");
      send["name"]=(picojson::value)string("tsumogiri_player");
      send["room"]=(picojson::value)string("default");
    }
  else if(o["type"].get<string>()=="start_game")
    {
      player_number=(int)o["id"].get<double>();
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="start_kyoku")
    {
      //o["bakaze"].get<string>();
      //o["kyoku"].get<double>();
      //o["honba"].get<double>();
      //o["kyotaku"].get<double>();
      //o["oya"].get<double>();
      //o["dora_marker"].get<string>();
      //o["tehais"].get<picojson::array>();
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="tsumo")
    {
      if(player_number==(int)o["actor"].get<double>())
	{
	  send["type"]=(picojson::value)string("dahai");
	  send["actor"]=(picojson::value)double(player_number);
	  send["pai"]=(picojson::value)string(o["pai"].get<string>());
	  send["tsumogiri"]=(picojson::value)bool(true);
	}
      else
	{
	  send["type"]=(picojson::value)string("none");
	}
    }
  else if(o["type"].get<string>()=="dahai")
    {
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="pon")
    {
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="chi")
    {
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="kakan")
    {
      send["type"]=(picojson::value)string("none"); 
    }
  else if(o["type"].get<string>()=="daiminkan")
    {
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="ankan")
    {
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="dora")
    {
      //o["dora_marker"].get<string>();
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="reach")
    {
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="reach_accepted")
    {
      //o["scores"];
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="hora")
    {
      //o["scores"];
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="ryukyoku")
    {
      //o["scores"];
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="end_kyoku")
    {
      send["type"]=(picojson::value)string("none");
    }
  else if(o["type"].get<string>()=="end_game")
    {
      return "end_game";
    }
  else if(o["type"].get<string>()=="error")
    {return "error";}
  picojson::value val(send);
  return val.serialize();
}
void handle_message(const std::string &message)
{
  //cout<<"handle_message"<<endl;
  //cout<<message<<endl;
  rec_message=message;
}

int game_main()
{
  using easywsclient::WebSocket;
  WebSocket::pointer ws = WebSocket::from_url("ws://www.logos.t.u-tokyo.ac.jp/mjai/");
  //assert(ws);

  while(ws->getReadyState()!=WebSocket::CLOSED)
    {
      while(1)
	{
	  rec_message="";
	  ws->poll();
	  ws->dispatch(handle_message);
	  if(rec_message!="")
	    {
	      cout<<rec_message<<endl;
	      if(rec_message.find("error")!=string::npos)
		{
		  cout<<"error "<<rec_message<<endl;
		  ws->close();
		  return 60;
		}
	      else if(rec_message.find("end_game")==string::npos)
		{
		  const char* buf_recv=rec_message.c_str();
		  string send_jason=ParseToGame(buf_recv);
		  ws->send(send_jason);	      
		  rec_message="";
		}
	      else
		{
		  ws->close();
		  return 1;
		}
	      break;
	    }
	}
    }
  ws->close();
  return 1;
}

int main()
{
  game_main();
  return 0;
}
