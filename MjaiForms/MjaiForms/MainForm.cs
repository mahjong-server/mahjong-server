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
        Idle, Dahai, Naki, NakiSelect, NakiSingleSelect
    }

    enum Alternatives
    {
        Tsumo, Ron, Reach, Pass, Pon, Chi, Ankan, Kakan, Daiminkan, Kyushu, Chankan
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
        public int kakan;

        public Furo(int target, int pai, List<int> consumed)
        {
            this.target = target;
            this.pai = pai;
            this.consumed = consumed;
            this.kakan = -1;
        }

        public bool is_kakan
        {
            get { return this.kakan != -1; }
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

        const int DORAS_OFFSET_X = KAWA_OFFSET_X + PAI_WIDTH * 6 + PAI_WIDTH / 3;
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
        List<List<bool>> kawaTsumogiris;
        List<int> reaches;
        List<List<Furo>> fuross;

        int nakiaskid = -1;
        int chankan_pai = -1;

        List<Alternatives> alternatives;

        List<bool> availablePai;

        private static int div(int a, int b) {
            if(a >= 0) return a / b;
            else return a / b - 1;
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            hostTextBox.Text = "mjai.hocha.org";
            portTextBox.Text = "11600";
            roomTextBox.Text = "default";
            nameTextBox.Text = "Unk_human";

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
            x *= 10;
            y *= 10;
            if (x % 100 == 0) x += 51;
            if (y % 100 == 0) y += 51;
            return x - y;
        }
        bool samePai(int x, int y)
        {
            return removeRed(x) == removeRed(y);
        }
        int removeRed(int x)
        {
            if (x <30 && x % 10 == 0) x += 5;
            return x;
        }
        int makeRed(int x)
        {
            if (x < 30 && x % 10 == 5) x -= 5;
            return x;
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
                    g.FillRectangle(new SolidBrush(Color.FromArgb(0x96, 0xAF, 0xA3)), new Rectangle(DORAS_OFFSET_X, DORAS_OFFSET_Y - 16, PAI_WIDTH * 5, PAI_HEIGHT + 16));
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
                    {
                        if (i == (kyoku - 1))
                        {
                            g.DrawString(names[i], font, Brushes.Red, new Point(185, 258));
                        }
                        else
                        {
                            g.DrawString(names[i], font, Brushes.Black, new Point(185, 258));
                        }

                    }

                    if (scores != null)
                        g.DrawString(scores[i].ToString(), font, Brushes.Black, new Point(193, 248));

                    if (tehais != null)
                    {
                        for (int j = 0; j < tehais[i].Count; j++)
                        {
                            var im = paiga[tehais[i][j]];
                            bool av = (i == id && availablePai != null && availablePai[j]);
                            var po = new Point(TEHAI_OFFSET_X + j * PAI_WIDTH, mainBox.Height - 10 - PAI_HEIGHT + (i == id && j == hovered && av ? -8 : 0));
                            g.DrawImage(im, po);
                            if (i == id && !av) 
                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.Black)), new Rectangle(po, new Size(PAI_WIDTH, PAI_HEIGHT)));
                            if (i == id && selecteds != null && selecteds.Any(_ => _ == j))
                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.OrangeRed)), new Rectangle(po, new Size(PAI_WIDTH, PAI_HEIGHT)));
                        }

                        if (i == id && state == State.Dahai)
                        {
                            g.FillRectangle(new SolidBrush(Color.Red), new Rectangle(TEHAI_OFFSET_X + (tehais[i].Count - 1) * PAI_WIDTH, mainBox.Height - 10, PAI_WIDTH, 3));
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

                            if (kawaTsumogiris!=null && kawaTsumogiris[i][j])
                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x60, Color.Azure)), rect);

                            if (kawaNakares != null && kawaNakares[i].Any(_ => _ == j))
                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.Black)), rect);

                            if (i == nakiaskid && j == kawas[i].Count-1)
                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.Yellow)), rect);

                        }
                    }

                    if (fuross != null)
                    {
                        int x = FUROS_OFFSET_X;
                        for (int j = 0; j < fuross[i].Count; j++)
                        {
                            Furo f = fuross[i][j];
                            
                            if (f.target == -1) //ankan
                            {
                                for (int k = 1; k <= 3; k++)
                                {
                                    x -= PAI_WIDTH;
                                    g.DrawImage(paiga[k == 2 ? makeRed(f.consumed[0]) : 30], new Point(x, FUROS_OFFSET_Y));
                                }
                            }
                            else
                            {
                                int relatedPos = (f.target - i + 4) % 4;
                                for (int k = 1; k <= 3; k++)
                                {
                                    if (k == relatedPos)
                                    {
                                        x -= PAI2_WIDTH;
                                        g.DrawImage(paiga2[f.pai], new Point(x, FUROS_OFFSET_Y + 8));

                                        if (f.is_kakan)
                                        {
                                            var po = new Point(x, FUROS_OFFSET_Y + 8 - PAI2_HEIGHT);
                                            g.DrawImage(paiga2[f.kakan], po);
                                            if (chankan_pai == f.kakan)
                                            {
                                                var rect = new Rectangle(po, new Size(PAI2_WIDTH, PAI2_HEIGHT));
                                                g.FillRectangle(new SolidBrush(Color.FromArgb(0x80, Color.Yellow)), rect);
                                            }
                                        }
                                    }
                                    else
                                    {
                                        x -= PAI_WIDTH;
                                        g.DrawImage(paiga[f.consumed[k - 1 - (k > relatedPos ? 1 : 0)]], new Point(x, FUROS_OFFSET_Y));
                                    }
                                }

                                if (f.consumed.Count == 3)
                                {
                                    g.DrawString("大明槓", font2, Brushes.Black, new Point(x, FUROS_OFFSET_Y));
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
                            nakiaskid = -1;
                            chankan_pai = -1;
                            tehais = (((string[][])json.tehais).Select<string[], List<int>>(tehai => (tehai.Select<string, int>(parsePai)).ToList<int>())).ToList<List<int>>();
                            for (int i = 0; i < 4; i++) tehais[i].Sort(new Comparison<int>(comparePai));
                            kawaTsumogiris = new List<List<bool>>();
                            for (int i = 0; i < 4; i++) kawaTsumogiris.Add(new List<bool>());
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
                        case "dora":
                            doras.Add(parsePai((string)json.dora_marker));
                            response = Protocol.none();
                            break;
                        case "tsumo":
                            if ((int)json.actor == id)
                            {
                                tehais[id].Sort(new Comparison<int>(comparePai));

                                pai = parsePai((string)json.pai);
                                tehais[id].Add(pai);
                                int shanten = Algorithm.shanten(tehais[id]);
                                println(shanten.ToString());

                                alternatives = new List<Alternatives>();
                                if (shanten == -1) alternatives.Add(Alternatives.Tsumo);
                                if (fuross[id].Where(_ => _.target != -1).Count() == 0 && shanten <= 0 && reaches[id] == -1) alternatives.Add(Alternatives.Reach);

                                if (json.IsDefined("possible_actions"))
                                {
                                    foreach (var vac in json.possible_actions)
                                    {
                                        if (vac.IsDefined("type") && vac.IsDefined("reason"))
                                        {
                                            if ((string)vac.type == "ryukyoku" && (string)vac.reason == "kyushukyuhai")
                                            {
                                                alternatives.Add(Alternatives.Kyushu);
                                            }
                                        }
                                    }
                                }

                                var kanzai = tehais[id].GroupBy(_ => removeRed(_)).Select(_ => new { pai = _.Key, cnt = _.Count() }).Where(_ => _.cnt == 4).Select(_ => _.pai);
                                if (kanzai.Count() > 0)
                                {
                                    alternatives.Add(Alternatives.Ankan);
                                }

                                var kakanzai = new List<int>();
                                foreach (var fr in fuross[id])
                                {
                                    if (fr.is_kakan == false && fr.target != -1 && samePai(fr.consumed[0], fr.consumed[1]))
                                    {
                                        if (tehais[id].Any(_ => samePai(_, fr.consumed[0])))
                                        {
                                            kakanzai.Add(fr.consumed[0]);
                                        }
                                    }
                                }
                                if (kakanzai.Count > 0)
                                {
                                    alternatives.Add(Alternatives.Kakan);
                                }


                                if (reaches[id] != -1)
                                {
                                    availablePai = Enumerable.Repeat(false, 14).ToList();
                                    availablePai[tehais[id].Count - 1] = true;
                                }
                                else
                                {
                                    availablePai = Enumerable.Repeat(true, 14).ToList();
                                }

                                if (shanten == -1 && autoHora.Checked)
                                {
                                    response = Protocol.hora(id, id, pai);
                                }
                                else if (reaches[id] != -1 && alternatives.Count == 0)
                                {
                                    response = Protocol.dahai(id, pai, true);
                                    tehais[id].RemoveAt(tehais[id].Count - 1);
                                    kawaTsumogiris[id].Add(true);
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
                                        bool tsumogiri = selected == tehais[id].Count - 1;
                                        response = Protocol.dahai(id, sute, tsumogiri);
                                        tehais[id].Remove(sute);
                                        tehais[id].Sort(new Comparison<int>(comparePai));
                                        kawaTsumogiris[id].Add(tsumogiri);
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
                                        else if(alt == Alternatives.Kyushu)
                                        {
                                            response = Protocol.kyushukyuhai(id);
                                        }
                                        else if (alt == Alternatives.Ankan)
                                        {
                                            alternatives.Clear();

                                            availablePai = Enumerable.Repeat(false, 14).ToList();
                                            foreach (var ka in kanzai)
                                            {
                                                int ind = tehais[id].FindIndex(p => samePai(p, ka));
                                                availablePai[ind] = true;
                                            }

                                            state = State.NakiSingleSelect;
                                            selection = Selection.Yet;
                                            selected = -1;

                                            BeginInvoke(new MethodInvoker(draw));

                                            while (true)
                                            {
                                                if (selection != Selection.Yet) break;
                                                Thread.Sleep(1);
                                            }
                                            state = State.Idle;

                                            int do_kan = tehais[id][selected];
                                            List<int> consumed = new List<int>();
                                            for (int i = 0; i < 4; i++)
                                            {
                                                int ix = tehais[id].FindIndex(p => samePai(p, do_kan));
                                                consumed.Add(tehais[id][ix]);
                                                tehais[id].RemoveAt(ix);
                                            }
                                            response = Protocol.ankan(id, consumed);

                                            availablePai = Enumerable.Repeat(reaches[id] == -1, 14).ToList();
                                        }
                                        else if (alt == Alternatives.Kakan)
                                        {
                                            alternatives.Clear();

                                            availablePai = Enumerable.Repeat(false, 14).ToList();
                                            foreach (var ka in kakanzai)
                                            {
                                                int ind = tehais[id].FindIndex(p => samePai(p, ka));
                                                availablePai[ind] = true;
                                            }

                                            state = State.NakiSingleSelect;
                                            selection = Selection.Yet;
                                            selected = -1;

                                            BeginInvoke(new MethodInvoker(draw));

                                            while (true)
                                            {
                                                if (selection != Selection.Yet) break;
                                                Thread.Sleep(1);
                                            }
                                            state = State.Idle;

                                            int do_kan = tehais[id][selected];
                                            List<int> consumed = new List<int>();
                                            foreach (var fr in fuross[id])
                                            {
                                                if (fr.is_kakan == false && fr.target != -1 && samePai(fr.consumed[0], fr.consumed[1]))
                                                {
                                                    if (samePai(do_kan, fr.consumed[0]))
                                                    {
                                                        consumed.Add(fr.consumed[0]);
                                                        consumed.Add(fr.consumed[1]);
                                                        consumed.Add(fr.pai);
                                                        break;
                                                    }
                                                }
                                            }
                                            tehais[id].RemoveAt(selected);
                                            response = Protocol.kakan(id, do_kan, consumed);

                                            availablePai = Enumerable.Repeat(true, 14).ToList();

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
                            reaches[actor] = kawas[actor].Count;

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
                                bool tsumogiri = selected == tehais[id].Count - 1;
                                response = Protocol.dahai(id, sute, tsumogiri);

                                tehais[id].Remove(sute);
                                tehais[id].Sort(new Comparison<int>(comparePai));
                                kawaTsumogiris[id].Add(tsumogiri);
                                kawas[id].Add(sute);
                            }

                            availablePai = Enumerable.Repeat(reaches[id] == -1, 14).ToList();

                            break;
                        case "reach_accepted":
                            actor = (int)json.actor;
                            scores = (List<int>)json.scores;
                            response = Protocol.none();
                            break;
                        case "dahai":
                            actor = (int)json.actor;
                            pai = parsePai((string)json.pai);

                            if (actor != id)
                            {
                                kawaTsumogiris[actor].Add((bool)json.tsumogiri);
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
                                    alternatives.Add(Alternatives.Daiminkan);
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
                                    nakiaskid = actor;

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

                                        if (pai < 30 && pai % 10 == 5 && tehais[id].Count(_ => samePai(_, pai)) == 3)
                                        {

                                            // 赤牌を含むか
                                            alternatives.Clear();

                                            availablePai = Enumerable.Repeat(false, 14).ToList();
                                            availablePai[tehais[id].IndexOf(pai)] = true;
                                            availablePai[tehais[id].IndexOf(pai - 5)] = true;

                                            state = State.NakiSingleSelect;
                                            selection = Selection.Yet;
                                            selected = -1;

                                            BeginInvoke(new MethodInvoker(draw));

                                            while (true)
                                            {
                                                if (selection != Selection.Yet) break;
                                                Thread.Sleep(1);
                                            }
                                            state = State.Idle;

                                            consumed.Add(tehais[id][selected]);
                                            tehais[id].Remove(tehais[id][selected]);
                                            consumed.Add(pai);
                                            tehais[id].Remove(pai);

                                            availablePai = Enumerable.Repeat(true, 14).ToList();
                                        }
                                        else
                                        {
                                            for (int i = 0; i < 2; i++)
                                            {
                                                int ix = tehais[id].FindIndex(p => samePai(p, pai));
                                                consumed.Add(tehais[id][ix]);
                                                tehais[id].RemoveAt(ix);
                                            }
                                        }
                                        response = Protocol.pon(id, actor, pai, consumed);
                                    }
                                    else if (alt == Alternatives.Daiminkan)
                                    {
                                        var consumed = new List<int>();
                                        for (int i = 0; i < 3; i++)
                                        {
                                            int ix = tehais[id].FindIndex(p => samePai(p, pai));
                                            consumed.Add(tehais[id][ix]);
                                            tehais[id].RemoveAt(ix);
                                        }
                                        response = Protocol.daiminkan(id, actor, pai, consumed);
                                    }
                                    else if (alt == Alternatives.Chi)
                                    {
                                        alternatives = new List<Alternatives>();
                                        selecteds = new List<int>();
                                        availablePai = Algorithm.chiAvailable(tehais[id], pai).ToList();

                                        while (true)
                                        {
                                            selecteds = new List<int>();
                                            selection = Selection.Yet;
                                            state = State.NakiSelect;
                                            BeginInvoke(new MethodInvoker(draw));

                                            while (true)
                                            {
                                                if (selection != Selection.Yet) break;
                                                Thread.Sleep(1);
                                            }

                                            state = State.Idle;

                                            selecteds.Sort();
                                            selecteds.Reverse();

                                            List<int> selhai = selecteds.Select(_ => tehais[id][_]).ToList();
                                            selhai.Add(pai);
                                            if (Algorithm.isShuntsu(selhai)) { break; }
                                        }

                                        response = Protocol.chi(id, actor, pai, selecteds.Select(_ => tehais[id][_]).ToList());

                                        for (int i = 0; i < selecteds.Count; i++)
                                            tehais[id].RemoveAt(selecteds[i]);

                                        availablePai = Enumerable.Repeat(true, 14).ToList();
                                        selecteds = new List<int>();
                                    }

                                    nakiaskid = -1;

                                }
                                
                            }
                            else /* 自分の打牌。tsumoのところで画面は更新してしまっているので、ここでは何もする必要がない */
                            {
                                response = Protocol.none();
                            }
                            break;
                        case "pon":
                        case "chi":
                            response = onNaki(json);
                            break;
                        case "ankan":
                        case "kakan":
                        case "daiminkan":
                            response = onKan(json);
                            break;
                        case "hora":
                        case "ryukyoku":
                            string caption;
                            if ((string)json.type == "hora")
                            {
                                int target = (int)json.target;
                                int ac = (int)json.actor;
                                
                                tehais[ac] = ((string[])json.hora_tehais).Select<string, int>(parsePai).ToList<int>();
                                if (target != ac)
                                {
                                    nakiaskid = target;
                                }
                                else
                                {
                                    tehais[ac].Add(parsePai((string)json.pai));
                                }

                                availablePai = Enumerable.Repeat(ac == id, 14).ToList();

                                caption = "和了 " + names[(int)json.actor];
                            }
                            else
                            {
                                var t_tehais = (((string[][])json.tehais).Select<string[], List<int>>(tehai => (tehai.Select<string, int>(parsePai)).ToList<int>())).ToList<List<int>>();
                                availablePai = Enumerable.Repeat(t_tehais[id][0] != parsePai("?"), 14).ToList();
                                
                                t_tehais[id] = tehais[id];
                                tehais = t_tehais;
                                caption = "流局 " + (string)json.reason;
                            }

                            scores = (List<int>)json.scores;
                            var delta = (List<int>)json.deltas;

                            string scorestr = "";
                            for (int i = 0; i < 4; i++)
                            {
                                int player = (i - id + 4) % 4;
                                int d = delta[player];
                                scorestr += names[player] + ": " + ((d > 0) ? "+" : "") + d + " (" + scores[player] + ")\n";
                            }
                            BeginInvoke(new MethodInvoker(draw));
                            MessageBox.Show(scorestr + "\n" + line, caption);
                            
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

        object onKan(dynamic json)
        {
            int actor = (int)json.actor;

            var consumed = (List<string>)json.consumed;

            if ((string)json.type == "daiminkan")
            {
                int target = (int)json.target;
                fuross[actor].Add(new Furo(target, parsePai((string)json.pai), consumed.Select(parsePai).ToList()));
            }
            else if ((string)json.type == "ankan")
            {
                fuross[actor].Add(new Furo(-1, -1, consumed.Select(parsePai).ToList()));
            }
            else if ((string)json.type == "kakan")
            {
                for (int i = 0; i < fuross[actor].Count; i++)
                {
                    if (fuross[actor][i].is_kakan == false && fuross[actor][i].target != -1 &&
                        samePai(fuross[actor][i].consumed[0], fuross[actor][i].consumed[1]) && samePai(fuross[actor][i].consumed[0], parsePai((string)json.pai)))
                    {
                        var kak = fuross[actor][i];
                        kak.kakan = (parsePai((string)json.pai));
                        fuross[actor][i] = kak;
                        break;
                    }
                }
            }

            if (actor != id)
            {
                if ((string)json.type == "kakan")
                {
                    int pai = parsePai((string)json.pai);

                    //chankan
                    if (Algorithm.shanten(tehais[id].Concat(new[] { pai })) == -1)
                    {
                        alternatives = new List<Alternatives>() { Alternatives.Pass, Alternatives.Chankan };

                        selection = Selection.Yet;
                        selected = -1;
                        state = State.Naki;
                        availablePai = Enumerable.Repeat(false, 14).ToList();
                        chankan_pai = pai;

                        BeginInvoke(new MethodInvoker(draw));

                        while (true)
                        {
                            if (selection != Selection.Yet) break;
                            Thread.Sleep(1);
                        }

                        chankan_pai = -1;
                        state = State.Idle;

                        Alternatives alt = alternatives[selected];
                        if (alt == Alternatives.Chankan)
                        {
                            return Protocol.hora(id, actor, pai);
                        }

                        availablePai = Enumerable.Repeat(reaches[id] == -1, 14).ToList();
                    }

                    tehais[actor].RemoveAt(0);
                }
                else
                {
                    for (int i = 0; i < consumed.Count; i++)
                        tehais[actor].RemoveAt(0);
                }
            }

            availablePai = Enumerable.Repeat(reaches[id] == -1, 14).ToList();

            object response = new { type = "none" };
            return response;
        }

        object onNaki(dynamic json)
        {
            int actor = (int)json.actor;
            var consumed = (List<string>)json.consumed;

            int target = (int)json.target;
            kawaNakares[target].Add(kawas[target].Count - 1);
            fuross[actor].Add(new Furo(target, parsePai((string)json.pai), consumed.Select(parsePai).ToList()));

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
                kawaTsumogiris[id].Add(false);
                kawas[id].Add(sute);
            }
            else
            {
                for (int i = 0; i < consumed.Count; i++)
                {
                    tehais[actor].RemoveAt(0);
                }
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

        private void mainBox_MouseClick(object sender, MouseEventArgs e)
        {

            Point p = mainBox.PointToClient(Cursor.Position);

            if (state == State.Dahai || state == State.Naki || state == State.NakiSingleSelect)
            {

                if (e.Button == MouseButtons.Right)
                {
                    if (state == State.Dahai && availablePai[tehais[id].Count - 1])
                    {
                        selection = Selection.PaiClick;
                        selected = tehais[id].Count - 1;
                    }
                    else
                    {
                        selection = Selection.ButtonClick;
                        selected = 0;
                    }
                }
                else if (p.Y >= TEHAI_OFFSET_Y && p.Y <= TEHAI_OFFSET_Y + PAI_HEIGHT)
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

        private void MainForm_FormClosing(object sender, FormClosingEventArgs e)
        {
            Environment.Exit(-1);
        }
    }
}
