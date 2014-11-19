using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using System.IO;
using System.Threading;
using System.Drawing.Imaging;
using System.Net.Sockets;
using Codeplex.Data;

namespace MjaiForms
{

    enum State
    {
        Idle, Dahai, Naki, NakiSelect
    }

    enum Alternatives
    {
        Tsumo, Ron, Reach, Pass, Pon, Chi
    }

    enum Selection
    {
        PaiClick, ButtonClick, PaiMultiClick, Yet
    }

    struct Furo
    {
        public int target;
        public int pai;
        public List<int> consumed;

        public Furo(int target, int pai, List<int> consumed)
        {
            this.target = target;
            this.pai = pai;
            this.consumed = consumed;
        }
    }

    public partial class MainForm : Form
    {
        public MainForm()
        {
            InitializeComponent();
        }

        const int PAI_WIDTH = 21;
        const int PAI_HEIGHT = 29;
        const int PAI2_WIDTH = 28;
        const int PAI2_HEIGHT = 22;

        const int MAINBOX_HEIGHT = 430;

        const int TEHAI_OFFSET_X = 78;
        const int TEHAI_OFFSET_Y = MAINBOX_HEIGHT - 10 - PAI_HEIGHT;
        const int KAWA_OFFSET_X = 152;
        const int KAWA_OFFSET_Y = 280;
        const int ALTERNATIVES_OFFSET_X = 380;
        const int ALTERNATIVES_OFFSET_Y = 350;
        const int ALTERNATIVES_WITDH = 80;
        const int ALTERNATIVES_HEIGHT = 30;

        const int FUROS_OFFSET_X = 420;
        const int FUROS_OFFSET_Y = MAINBOX_HEIGHT - 10 - PAI_HEIGHT;

        const int DORAS_OFFSET_X = KAWA_OFFSET_X + PAI_WIDTH * 7;
        const int DORAS_OFFSET_Y = KAWA_OFFSET_Y + PAI_HEIGHT * 3 / 2;

        string[] KYOKU_STR = new string[] { "東1", "東2", "東3", "東4", "南1", "南2", "南3", "南4", "西1", "西2", "西3", "西4", "北1", "北2", "北3", "北4" };

        Image[] paiga;
        Image[] paiga2;
        Font font;
        Font font2;

        State state;

        Selection selection;
        int selected = -1;
        List<int> selecteds;

        int hovered = -1;

        int id = -1;

        int kyoku = -1;
        int honba = -1;
        int kyotaku = -1;
        List<string> names;
        List<int> scores;
        List<int> doras;
        List<List<int>> tehais;
        List<List<int>> kawas;
        List<List<int>> kawaNakares;
        List<int> reaches;
        List<List<Furo>> fuross;

        List<Alternatives> alternatives;

        List<bool> availablePai;

        private static int div(int a, int b) {
            if(a >= 0) return a / b;
            else return a / b - 1;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            hostTextBox.Text = "133.242.133.31";
            portTextBox.Text = "11600";
            roomTextBox.Text = "default";
            nameTextBox.Text = "wistery_k";

            state = State.Idle;

            selected = -1;

            paiga = new Image[40];
            paiga2 = new Image[40];

            for (int i = 0; i < 40; i++)
            {
                StringBuilder sb = new StringBuilder();
                sb.Append("mpsz"[i / 10]);
                sb.Append(i % 10);
                string tmp = sb.ToString();
                paiga[i] = Image.FromFile(string.Format("../../paiga/{0}.png", tmp));
                paiga2[i] = Image.FromFile(string.Format("../../paiga/y_{0}.png", tmp));
            }

            font = new Font("MS UI Gothic", 12);
            font2 = new Font("MS UI Gothic", 9);

            Algorithm.init();

            mainBox.Image = new Bitmap(mainBox.Width, mainBox.Height, PixelFormat.Format32bppArgb);

            draw();

        }

        private void button1_Click(object sender, EventArgs e)
        {
            connectButton.Enabled = false;
            new Thread(main).Start();
        }

        int parsePai(string s)
        {
            int len = s.Length;
            if (len == 1)
            {
                return "?ESWNPFC".IndexOf(s[0]) + 30;
            }
            else if (len == 2)
            {
                return (s[0] - '0') + "mps".IndexOf(s[1]) * 10;
            }
            else if (len == 3)
            {
                return "mps".IndexOf(s[1]) * 10;
            }
            else
            {
                throw new Exception();
            }
        }

        int comparePai(int x, int y)
        {
            if (x % 10 == 0) x += 5;
            if (y % 10 == 0) y += 5;
            return x - y;
        }

        void draw()
        {
            using (var g = Graphics.FromImage(mainBox.Image))
            {
                g.Clear(Color.FromArgb(0xC0, 0xD4, 0xC3));
                g.FillRectangle(new SolidBrush(Color.FromArgb(0x96, 0xAF, 0xA3)), new Rectangle(155, 155, 120, 120));

                if(kyoku != -1)
                    g.DrawString(KYOKU_STR[(kyoku - 1) % 16], font, Brushes.Black, new Point(200, 190));

                g.FillRectangle(Brushes.White, new Rectangle(200, 215, 5, 25));

                for (int i = 0; i < 5; i++)
                {
                    for (int j = 0; j < 2; j++)
                    {
                        g.FillEllipse(Brushes.Black, new Rectangle(200 + 2 * j, 222 + 2 * i, 2, 2));
                    }
                }           

                if (honba != -1)
                    g.DrawString(honba.ToString(), font2, Brushes.Black, new Point(207, 224));

                g.FillRectangle(Brushes.White, new Rectangle(200 + 20, 215, 5, 25));
                g.FillEllipse(Brushes.Red, new Rectangle(200 + 20, 226, 4, 4));

                if (kyotaku != -1)
                    g.DrawString(kyotaku.ToString(), font2, Brushes.Black, new Point(207 + 20, 224));

                if (doras != null)
                {
                    g.FillRectangle(new SolidBrush(Color.FromArgb(0x96, 0xAF, 0xA3)), new Rectangle(DORAS_OFFSET_X, DORAS_OFFSET_Y - 16, PAI_WIDTH * 4, PAI_HEIGHT + 16));
                    g.DrawString("ドラ表示", font2, Brushes.Black, new Point(DORAS_OFFSET_X, DORAS_OFFSET_Y - 15));
                    for (int i = 0; i < doras.Count; i++)
                    {
                        g.DrawImage(paiga[doras[i]], new Point(DORAS_OFFSET_X + PAI_WIDTH * i, DORAS_OFFSET_Y));
                    }
                }

                for (int i = 0; i < 4; i++)
                {
                    g.ResetTransform();
                    g.TranslateTransform(mainBox.Width / 2, mainBox.Height / 2);
                    g.RotateTransform(-90 * ((i - id + 4) % 4));
                    g.TranslateTransform(-mainBox.Width / 2, -mainBox.Height / 2);

                    if (reaches != null)
                    {
                        if (reaches[i] != -1)
                        {
                            g.FillRectangle(Brushes.White, new Rectangle(175, 268, 80, 7));
                            g.FillEllipse(Brushes.Red, new Rectangle(213, 270, 4, 4));
                        }
                    }

                    if (names != null)
                        g.DrawString(names[i], font, Brushes.Black, new Point(185, 258));

                    if (scores != null)
                        g.DrawString(scores[i].ToString(), font, Brushes.Black, new Point(193, 248));

                    if (tehais != null)
                    {
                        for (int j = 0; j < tehais[i].Count; j++)
                        {
                            var im = paiga[tehais[i][j]];
                            bool av = (i == id && availablePai != null && availablePai[j]);
                            var po = new Point(TEHAI_OFFSET_X + j * 21, mainBox.Height - 10 - PAI_HEIGHT + (i == id && j == hovered && av ? -8 : 0));
                            g.DrawImage(im, po);
                            if (i == id && !av) 
                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.Black)), new Rectangle(po, new Size(PAI_WIDTH, PAI_HEIGHT)));
                            if (i == id && selecteds != null && selecteds.Any(_ => _ == j))
                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.OrangeRed)), new Rectangle(po, new Size(PAI_WIDTH, PAI_HEIGHT)));
                        }
                    }

                    if (kawas != null)
                    {
                        for (int j = 0; j < kawas[i].Count; j++)
                        {
                            Image im;
                            Point po;
                            Rectangle rect;
                            if (j == reaches[i])
                            {
                                im = paiga2[kawas[i][j]];
                                po = new Point(KAWA_OFFSET_X + (j % 6) * 21, KAWA_OFFSET_Y + j / 6 * 29 + 8);
                                rect = new Rectangle(po, new Size(PAI2_WIDTH, PAI2_HEIGHT));
                                
                                
                            }
                            else {
                                im = paiga[kawas[i][j]];
                                po = new Point(KAWA_OFFSET_X + (j % 6) * 21, KAWA_OFFSET_Y + j / 6 * 29);
                                rect = new Rectangle(po, new Size(PAI_WIDTH, PAI_HEIGHT));
                            }

                            g.DrawImage(im, po);

                            if (kawaNakares != null && kawaNakares[i].Any(_ => _ == j))
                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.Black)), rect);

                        }
                    }

                    if (fuross != null)
                    {
                        int x = FUROS_OFFSET_X;
                        for (int j = 0; j < fuross[i].Count; j++)
                        {
                            Furo f = fuross[i][j];
                            int relatedPos = (f.target - i + 4) % 4;
                            for (int k = 1; k <= 3; k++)
                            {
                                if (k == relatedPos)
                                {
                                    x -= PAI2_WIDTH;
                                    g.DrawImage(paiga2[f.pai], new Point(x, FUROS_OFFSET_Y + 8));
                                }
                                else
                                {
                                    x -= PAI_WIDTH;
                                    g.DrawImage(paiga[f.consumed[k - 1 - (k > relatedPos ? 1 : 0)]], new Point(x, FUROS_OFFSET_Y));
                                }
                            }
                        }
                    }
                }

                g.ResetTransform();

                if (alternatives != null && (state == State.Dahai || state == State.Naki))
                {
                    int x = ALTERNATIVES_OFFSET_X;
                    foreach (var alt in alternatives)
                    {
                        x -= 80;
                        g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.Black)), new Rectangle(x, ALTERNATIVES_OFFSET_Y, ALTERNATIVES_WITDH, ALTERNATIVES_HEIGHT));

                        g.DrawString(alt.ToString(), font, Brushes.White, new RectangleF(x, ALTERNATIVES_OFFSET_Y, ALTERNATIVES_WITDH, ALTERNATIVES_HEIGHT));
                    }
                }

            }
            mainBox.Refresh();
        }

        void main()
        {
            println("starting connection...");
            TcpClient tcp = null;
            try
            {
                tcp = new TcpClient(hostTextBox.Text, Int32.Parse(portTextBox.Text));
                tcp.NoDelay = true;
            }
            catch (SocketException e)
            {
                println("failed to connect.");
                println(e.Message);
                enableConnectButton();
                return;
            }

            println("connected.");

            using (var reader = new StreamReader(tcp.GetStream()))
            using (var writer = new StreamWriter(tcp.GetStream()))
            {
                while (true)
                {
                    string line = reader.ReadLine();
                    if (line == null) continue;
                    println(string.Format("<-\t{0}", line));
                    var json = DynamicJson.Parse(line);
                    
                    object response = null;

                    int pai;
                    int actor;

                    switch ((string)json.type)
                    {
                        case "hello":
                            response = Protocol.join(nameTextBox.Text, roomTextBox.Text);
                            break;
                        case "start_game":
                            id = (int)json.id;
                            names = ((string[])json.names).ToList<string>();
                            scores = new List<int>();
                            for (int i = 0; i < 4; i++) scores.Add(25000);
                            response = Protocol.none();
                            break;
                        case "end_game":
                            goto endwhile;
                        case "start_kyoku":
                            kyoku = (int)json.kyoku;
                            honba = (int)json.honba;
                            kyotaku = (int)json.kyotaku;
                            tehais = (((string[][])json.tehais).Select<string[], List<int>>(tehai => (tehai.Select<string, int>(parsePai)).ToList<int>())).ToList<List<int>>();
                            kawas = new List<List<int>>();
                            for(int i = 0; i < 4; i++) kawas.Add(new List<int>());
                            reaches = new List<int>();
                            for (int i = 0; i < 4; i++) reaches.Add(-1);
                            fuross = new List<List<Furo>>();
                            for (int i = 0; i < 4; i++) fuross.Add(new List<Furo>());
                            kawaNakares = new List<List<int>>();
                            for (int i = 0; i < 4; i++) kawaNakares.Add(new List<int>());
                            doras = new List<int>();
                            doras.Add(parsePai((string)json.dora_marker));
                            response = Protocol.none();
                            break;
                        case "tsumo":
                            if ((int)json.actor == id)
                            {
                                pai = parsePai((string)json.pai);
                                tehais[id].Add(pai);
                                int shanten = Algorithm.shanten(tehais[id]);
                                println(shanten.ToString());

                                alternatives = new List<Alternatives>();
                                if (shanten == -1) alternatives.Add(Alternatives.Tsumo);
                                if (fuross[id].Count == 0 && shanten <= 0 && reaches[id] == -1) alternatives.Add(Alternatives.Reach);

                                if (reaches[id] != -1)
                                {
                                    availablePai = Enumerable.Repeat(false, 14).ToList();
                                    availablePai[tehais[id].Count - 1] = true;
                                }
                                else
                                {
                                    availablePai = Enumerable.Repeat(true, 14).ToList();
                                }

                                if (alternatives.Any(_ => _ == Alternatives.Tsumo) && autoHora.Checked)
                                {
                                    response = Protocol.hora(id, id, pai);
                                }
                                else if (reaches[id] != -1)
                                {
                                    response = Protocol.dahai(id, pai, true);
                                    tehais[id].RemoveAt(tehais[id].Count - 1);
                                    kawas[id].Add(pai);
                                }
                                else
                                {

                                    state = State.Dahai;
                                    selection = Selection.Yet;
                                    selected = -1;

                                    BeginInvoke(new MethodInvoker(draw));

                                    while (true)
                                    {
                                        if (selection != Selection.Yet) break;
                                        Thread.Sleep(1);
                                    }
                                    state = State.Idle;
                                    if (selection == Selection.PaiClick)
                                    {
                                        var sute = tehais[id][selected];
                                        response = Protocol.dahai(id, sute, selected == tehais[id].Count - 1);
                                        tehais[id].Remove(sute);
                                        tehais[id].Sort(new Comparison<int>(comparePai));
                                        kawas[id].Add(sute);
                                    }
                                    else if (selection == Selection.ButtonClick)
                                    {
                                        Alternatives alt = alternatives[selected];
                                        if (alt == Alternatives.Tsumo)
                                        {
                                            response = Protocol.hora(id, id, pai);
                                        }
                                        else if (alt == Alternatives.Reach)
                                        {
                                            response = Protocol.reach(id);
                                        }
                                    }

                                }
                            }
                            else
                            {
                                tehais[(int)json.actor].Add(parsePai((string)json.pai));
                                response = Protocol.none();
                            }

                            availablePai = Enumerable.Repeat(reaches[id] == -1, 14).ToList();
                           
                            break;
                        case "reach":
                            actor = (int)json.actor;

                            if (actor != id)
                            {
                                response = Protocol.none();
                            }
                            else
                            {
                                alternatives = new List<Alternatives>();
                                state = State.Dahai;
                                selection = Selection.Yet;
                                selected = -1;

                                for (int i = 0; i < tehais[id].Count; i++)
                                {
                                    availablePai[i] = Algorithm.shanten(tehais[id].Take(i).Concat(tehais[id].Skip(i + 1))) == 0;
                                }

                                while (true)
                                {
                                    if (selection != Selection.Yet) break;
                                    Thread.Sleep(1);
                                }
                                state = State.Idle;

                                var sute = tehais[id][selected];
                                response = Protocol.dahai(id, sute, selected == tehais[id].Count - 1);

                                tehais[id].Remove(sute);
                                tehais[id].Sort(new Comparison<int>(comparePai));
                                kawas[id].Add(sute);
                            }

                            availablePai = Enumerable.Repeat(reaches[id] == -1, 14).ToList();

                            break;
                        case "reach_accepted":
                            actor = (int)json.actor;
                            reaches[actor] = kawas[actor].Count - 1;
                            scores = (List<int>)json.scores;
                            response = Protocol.none();
                            break;
                        case "dahai":
                            actor = (int)json.actor;
                            pai = parsePai((string)json.pai);

                            if (actor != id)
                            {
                                if ((bool)json.tsumogiri)
                                {
                                    tehais[actor].RemoveAt(tehais[actor].Count - 1);
                                    kawas[actor].Add(pai);
                                }
                                else
                                {
                                    int index = new Random().Next(tehais[actor].Count);
                                    tehais[actor].RemoveAt(index);
                                    kawas[actor].Add(pai);
                                }

                                alternatives = new List<Alternatives>() { Alternatives.Pass };

                                if (Algorithm.shanten(tehais[id].Concat(new[] { pai })) == -1)
                                {
                                    alternatives.Add(Alternatives.Ron);
                                }

                                if (reaches[id] == -1 && (actor - id + 4) % 4 == 3 && Algorithm.canChi(tehais[id], pai))
                                {
                                    alternatives.Add(Alternatives.Chi);
                                }
                                if (reaches[id] == -1 && Algorithm.canPon(tehais[id], pai))
                                {
                                    alternatives.Add(Alternatives.Pon);
                                }
                                if (reaches[id] == -1 && Algorithm.canKan(tehais[id], pai))
                                {
                                    alternatives.Add(Alternatives.Kan);
                                }
                                
                                if (alternatives.Any(_ => _ == Alternatives.Ron && autoHora.Checked))
                                {
                                    response = response = Protocol.hora(id, actor, pai);
                                }
                                else if (alternatives.Count == 1 || nakiNashi.Checked)
                                {
                                    response = Protocol.none();
                                }
                                else
                                {
                                    selection = Selection.Yet;
                                    selected = -1;
                                    state = State.Naki;
                                    availablePai = Enumerable.Repeat(false, 14).ToList();

                                    BeginInvoke(new MethodInvoker(draw));

                                    while (true)
                                    {
                                        if (selection != Selection.Yet) break;
                                        Thread.Sleep(1);
                                    }

                                    state = State.Idle;

                                    Alternatives alt = alternatives[selected];
                                    if (alt == Alternatives.Pass)
                                        response = Protocol.none();
                                    else if (alt == Alternatives.Ron)
                                        response = Protocol.hora(id, actor, pai);
                                    else if (alt == Alternatives.Pon)
                                    {
                                        List<int> consumed = new List<int>();
                                        for (int i = 0; i < 2; i++)
                                        {
                                            int ix = tehais[id].FindIndex(p => comparePai(p, pai) == 0);
                                            consumed.Add(tehais[id][ix]);
                                            tehais[id].RemoveAt(ix);
                                        }
                                        response = Protocol.pon(id, actor, pai, consumed);
                                    }
                                    else if (alt == Alternatives.Kan)
                                    {
                                        response = Protocol.pon(id, actor, pai, Enumerable.Repeat(pai, 3).ToList());
                                        for (int i = 0; i < 3; i++) tehais[id].Remove(pai);
                                    }
                                    else if (alt == Alternatives.Chi)
                                    {
                                        alternatives = new List<Alternatives>();
                                        selection = Selection.Yet;
                                        selecteds = new List<int>();
                                        state = State.NakiSelect;
                                        availablePai = Enumerable.Repeat(true, 14).ToList();

                                        BeginInvoke(new MethodInvoker(draw));

                                        while (true)
                                        {
                                            if (selection != Selection.Yet) break;
                                            Thread.Sleep(1);
                                        }

                                        state = State.Idle;

                                        selecteds.Sort();
                                        selecteds.Reverse();

                                        response = Protocol.chi(id, actor, pai, selecteds.Select(_ => tehais[id][_]).ToList());

                                        for (int i = 0; i < selecteds.Count; i++)
                                            tehais[id].RemoveAt(selecteds[i]);

                                        selecteds = new List<int>();
                                    }

                                }
                                
                            }
                            else /* 自分の打牌。tsumoのところで画面は更新してしまっているので、ここでは何もする必要がない */
                            {
                                response = Protocol.none();
                            }
                            break;
                        case "pon":
                            response = onNaki(json);
                            break;
                        case "chi":
                            response = onNaki(json);
                            break;
                        case "kan":
                            response = onNaki(json);
                            break;
                        case "hora":
                            scores = (List<int>)json.scores;
                            response = Protocol.none();
                            break;
                        case "ryukyoku":
                            scores = (List<int>)json.scores;
                            response = Protocol.none();
                            break;
                        case "error":
                            println("!!! ERROR OCCURRED !!!");
                            goto endwhile;
                        default:
                            response = Protocol.none();
                            break;
                    }

                    BeginInvoke(new MethodInvoker(draw));

                    string rawResponse = DynamicJson.Serialize(response);
                    println(string.Format("->\t{0}", rawResponse));
                    writer.WriteLine(rawResponse);
                    writer.Flush();
                }
            endwhile: ;
               
            }
            enableConnectButton();
        }

        object onNaki(dynamic json)
        {
            int actor = (int)json.actor;
            int target = (int)json.target;

            fuross[actor].Add(new Furo(target, parsePai((string)json.pai), ((List<string>)json.consumed).Select(parsePai).ToList()));
            kawaNakares[target].Add(kawas[target].Count - 1);

            object response = null;
            if (actor == id)
            {
                alternatives = new List<Alternatives>();

                availablePai = Enumerable.Repeat(true, 14).ToList();
                state = State.Dahai;
                selection = Selection.Yet;
                selected = -1;

                BeginInvoke(new MethodInvoker(draw));

                while (true)
                {
                    if (selection != Selection.Yet) break;
                    Thread.Sleep(1);
                }
                state = State.Idle;

                var sute = tehais[id][selected];
                response = Protocol.dahai(id, sute, false);
                tehais[id].Remove(sute);
                tehais[id].Sort(new Comparison<int>(comparePai));
                kawas[id].Add(sute);
            }
            else
            {
                for (int i = 0; i < ((List<string>)json.consumed).Count; i++)
                    tehais[actor].RemoveAt(0);
                response = new { type = "none" };
            }
            availablePai = Enumerable.Repeat(reaches[id] == -1, 14).ToList();
            return response;
        }

        void println(string s)
        {
            if (debugTextBox.InvokeRequired)
            {
                BeginInvoke(new Action<string>(println), new object[] { s });
                return;
            }
            debugTextBox.AppendText(s + "\r\n");
            debugTextBox.SelectionStart = debugTextBox.Text.Length;
            debugTextBox.ScrollToCaret();
        }

        void enableConnectButton()
        {
            if (connectButton.InvokeRequired)
            {
                BeginInvoke(new MethodInvoker(enableConnectButton));
                return;
            }
            connectButton.Enabled = true;
        }

        private void mainBox_Click(object sender, EventArgs e)
        {

            Point p = mainBox.PointToClient(Cursor.Position);

            if (state == State.Dahai || state == State.Naki)
            {

                if (p.Y >= TEHAI_OFFSET_Y && p.Y <= TEHAI_OFFSET_Y + PAI_HEIGHT)
                {

                    int sel = div(p.X - TEHAI_OFFSET_X, PAI_WIDTH);
                    if (sel >= 0 && sel < tehais[id].Count && availablePai[sel])
                    {
                        selection = Selection.PaiClick;
                        selected = sel;
                    }
                }
                else if (p.Y >= ALTERNATIVES_OFFSET_Y && p.Y <= ALTERNATIVES_OFFSET_Y + ALTERNATIVES_HEIGHT)
                {
                    int sel = div(ALTERNATIVES_OFFSET_X - p.X, ALTERNATIVES_WITDH);
                    if (sel >= 0 && sel < alternatives.Count)
                    {
                        selection = Selection.ButtonClick;
                        selected = sel;
                    }
                }
            }
            else if (state == State.NakiSelect)
            {
                if (p.Y >= TEHAI_OFFSET_Y && p.Y <= TEHAI_OFFSET_Y + PAI_HEIGHT)
                {

                    int sel = div(p.X - TEHAI_OFFSET_X, PAI_WIDTH);
                    if (sel >= 0 && sel < tehais[id].Count && availablePai[sel])
                    {
                        
                        if (!selecteds.Remove(sel))
                        {
                            selecteds.Add(sel);
                            if (selecteds.Count == 2) selection = Selection.PaiMultiClick;
                        }
                    }
                }
            }
        }

        private void mainBox_MouseMove(object sender, MouseEventArgs e)
        {
            int u = TEHAI_OFFSET_Y;
            Point p = mainBox.PointToClient(Cursor.Position);

            if (p.Y >= u && p.Y <= u + PAI_HEIGHT && p.X - TEHAI_OFFSET_X > 0)
                hovered = (p.X - TEHAI_OFFSET_X) / PAI_WIDTH;
            else
                hovered = -1;
            draw();
        }
    }
}
