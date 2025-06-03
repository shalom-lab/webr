<template>
    <div>
        <pre><code id="out">Loading webR, please wait...</code></pre>
        <input spellcheck="false" autocomplete="off" id="input" v-model="input">
        <button @click="sendInput()" id="run">Run</button>
    </div>
</template>

<script>
export default {
    data() {
        return {
            input: '1+1'
        }
    },
    async mounted() {
        console.log(123)
        await this.webR.init()
        this.my = new this.webRConsole({
            stdout: line => console.log(line),
            stderr: line => console.log(line),
            prompt: p => console.log(p),
        });
        console.log(456)
        this.my.run();
        this.my.stdin('1+1')
    },
    methods: {
        sendInput() {
            this.webRConsole.stdin(this.input);
            document.getElementById('out').append(this.input + '\n');
            this.input = "";
        }
    }
}
</script>

<style></style>